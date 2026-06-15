import std/strformat

import ports/opengl
import shaders/base
import shaders/compile
import core

type
  Pipeline* = object
    shader*: Shader
    count: int
    indexType: GLenum
    vao: GLuint
    vbo: GLuint
    ibo: GLuint

proc destroy*(p: ptr Pipeline) =
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
  destroy(addr p.shader)

proc pipeline*[V, I](shader: Shader, vertices: openArray[V], indices: openArray[I]): Pipeline =
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
    stride = shader.layout.stride
    offset = 0
  for attr in shader.layout.attrs:
    glVertexAttribPointer(attr.index.GLuint, attr.count.GLint, cGL_FLOAT, false, stride.GLsizei, cast[pointer](offset))
    glEnableVertexAttribArray(attr.index.GLuint)
    offset += attr.size

  glGenBuffers(1, result.ibo.addr)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, result.ibo)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, (len(indices) * sizeof(I)).GLsizeiptr, cast[pointer](addr indices[0]), GL_STATIC_DRAW)

  #glBindVertexArray(0)
  #glBindBuffer(GL_ARRAY_BUFFER, 0)
  #glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

proc render*(g: ptr Graphics, p: var Pipeline) =
  use(p.shader)
  glBindVertexArray(p.vao)
  glDrawElements(GL_TRIANGLES, p.count.GLsizei, p.indexType, cast[pointer](0))
