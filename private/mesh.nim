import std/strformat

import ports/opengl
import shader
import glsl
import core
import transform
import camera

type
  Mesh* = object
    shader*: Shader
    count: int
    indexType: GLenum
    vao: GLuint
    vbo: GLuint
    ibo: GLuint


proc destroy*(p: var Mesh) =
  if p.ibo != 0:
    glDeleteBuffers(1, p.ibo.addr)
    echo &"- Index buffer [{p.ibo.int}] destroyed."
    p.ibo = 0
  if p.vbo != 0:
    glDeleteBuffers(1, p.vbo.addr)
    echo &"- Vertex buffer [{p.vbo.int}] destroyed."
    p.vbo = 0
  if p.vao != 0:
    glDeleteVertexArrays(1, p.vao.addr)
    echo &"- Vertex array [{p.vao.int}] destroyed."
    p.vao = 0
  destroy(p.shader)

proc mesh*[V, I](g: ptr Graphics, shader: Shader, vertices: openArray[V], indices: openArray[I]): Mesh =
  discard g
  result.shader = shader
  result.count = len(indices)
  when sizeof(I) == sizeof(uint8):
    result.indexType = GL_UNSIGNED_BYTE
  elif sizeof(I) == sizeof(uint16):
    result.indexType = GL_UNSIGNED_SHORT
  elif sizeof(I) == sizeof(uint32):
    result.indexType = GL_UNSIGNED_INT
  else:
    {.error: "Unsupported index buffer element type".}

  use(result.shader)
  glGenVertexArrays(1, result.vao.addr)
  glBindVertexArray(result.vao)

  glGenBuffers(1, result.vbo.addr)
  glBindBuffer(GL_ARRAY_BUFFER, result.vbo)
  glBufferData(GL_ARRAY_BUFFER, (len(vertices) * sizeof(V)).GLsizeiptr, cast[pointer](addr vertices[0]), GL_STATIC_DRAW)

  var
    stride = result.shader.layout.stride
    offset = 0
  for attr in result.shader.layout.attrs:
    glVertexAttribPointer(attr.index.GLuint, attr.count.GLint, cGL_FLOAT, false, stride.GLsizei, cast[pointer](offset))
    glEnableVertexAttribArray(attr.index.GLuint)
    offset += attr.size

  glGenBuffers(1, result.ibo.addr)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, result.ibo)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, (len(indices) * sizeof(I)).GLsizeiptr, cast[pointer](addr indices[0]), GL_STATIC_DRAW)

  glBindVertexArray(0)
  glBindBuffer(GL_ARRAY_BUFFER, 0)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

  return result


proc setCameraData(g: ptr Graphics, shader: var Shader, camera: Camera) =
  let
    invView = camera.transform.world
    view = inverse(invView)
    viewProjection = view * camera.projection
  shader["GLSL_CAMERA.PROJECTION"] = camera.projection
  shader["GLSL_CAMERA.VIEW"] = inverse(invView)
  shader["GLSL_CAMERA.VIEW_PROJECTION"] = viewProjection
  shader["GLSL_CAMERA.INV_PROJECTION"] = inverse(camera.projection)
  shader["GLSL_CAMERA.INV_VIEW"] = invView
  shader["GLSL_CAMERA.INV_VIEW_PROJECTION"] = inverse(viewProjection)
  shader["GLSL_CAMERA.NEAR_PLANE"] = camera.nearZ
  shader["GLSL_CAMERA.FAR_PLANE"] = camera.farZ
  shader["GLSL_CAMERA.ASPECT"] = g.aspect


proc render*(g: ptr Graphics, p: var Mesh, camera: Camera) =
  use(p.shader)
  setCameraData(g, p.shader, camera)
  glBindVertexArray(p.vao)
  glDrawElements(GL_TRIANGLES, p.count.GLsizei, p.indexType, cast[pointer](0))

template shader*(g: ptr Graphics, vx, fx: untyped): Shader =
  var
    r = toGLSL(vx)
    fs = toGLSL(fx)[0]
    vs = r[0]
    layout = r[1]
    source = vs & "\n" & fs
  Shader(
    program: createProgram(
      vs,
      fs,
    ),
    layout: layout,
    source: source,
  )
