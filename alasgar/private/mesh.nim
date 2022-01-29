import sequtils
import hashes

import ports/opengl
import utils
import container


type
    Vertex* {.packed.} = object
        position*: Vec3
        normal*: Vec3
        uv*: Vec2

    Mesh* = ref object
        vertexArrayObject: GLuint
        vertexBufferObject: GLuint
        modelBufferObject: GLuint
        materialBufferObject: GLuint
        spriteBufferObject: GLuint
        count*: GLsizei
        vMin*: Vec3
        vMax*: Vec3
        vRadius*: float32
        drawMode: GLenum
        bufferMode: GLenum
        indices: seq[uint32]

proc destroyMesh(mesh: Mesh) =
    if mesh.vertexBufferObject != 0:
        echo &"Destroying mesh[{mesh.vertexBufferObject}]..."
        glDeleteBuffers(1, mesh.spriteBufferObject.addr)
        glDeleteBuffers(1, mesh.materialBufferObject.addr)
        glDeleteBuffers(1, mesh.modelBufferObject.addr)
        glDeleteVertexArrays(1, mesh.vertexArrayObject.addr)
        glDeleteBuffers(1, mesh.vertexBufferObject.addr)

        mesh.spriteBufferObject = 0
        mesh.materialBufferObject = 0
        mesh.modelBufferObject = 0
        mesh.vertexArrayObject = 0
        mesh.vertexBufferObject = 0

var cache = newCachedContainer[Mesh](destroyMesh)

const VECTOR4F_SIZE_BYTES = 4 * sizeof(float32)
var bufferSizeOf: int = 0 # Drawable size as stride

proc setBufferSizeOf*(size: int) = bufferSizeOf = size
func caddr*(v: var Vertex): ptr float32 = v.position.caddr
func `$`*(v: Mesh): string = &"Vertices: [{v.count / 3}] triangles"

proc newMesh*(data: var openArray[Vertex], indices: openArray[uint32], drawMode: GLenum = GL_TRIANGLES, bufferMode: GLenum = GL_STATIC_DRAW): Mesh =
    new(result)
    result.drawMode = drawMode
    result.bufferMode = bufferMode

    # Copies indices
    if len(indices) > 0:
        result.indices = toSeq[indices]

    for v in data:
        if v.position.x < result.vMin.x:
            result.vMin.x = v.position.x
        if v.position.x > result.vMax.x:
            result.vMax.x = v.position.x
        if v.position.y < result.vMin.y:
            result.vMin.y = v.position.y
        if v.position.y > result.vMax.y:
            result.vMax.y = v.position.y
        if v.position.z < result.vMin.z:
            result.vMin.z = v.position.z
        if v.position.z > result.vMax.z:
            result.vMax.z = v.position.z

    # Calculates volume radius out of mesh bounderies
    result.vRadius = length(result.vMax - result.vMin) / 2

    glGenVertexArrays(1, result.vertexArrayObject.addr)
    glBindVertexArray(result.vertexArrayObject)

    glGenBuffers(1, result.vertexBufferObject.addr)
    glBindBuffer(GL_ARRAY_BUFFER, result.vertexBufferObject)

    # Marks data chunks and index them, it determines where the data is located in buffer
    var offset = 0
    var stride = sizeof(data[0]).GLsizei

    glEnableVertexAttribArray(0.GLuint)
    glVertexAttribPointer(0.GLuint, 3, cGL_FLOAT, false, stride, cast[pointer](0))
    offset += 3 * sizeof(float32)

    glEnableVertexAttribArray(1.GLuint)
    glVertexAttribPointer(1.GLuint, 3, cGL_FLOAT, false, stride, cast[pointer](offset))
    offset += 3 * sizeof(float32)

    glEnableVertexAttribArray(2.GLuint)
    glVertexAttribPointer(2.GLuint, 2, cGL_FLOAT, false, stride, cast[pointer](offset))
    offset += 2 * sizeof(float32)

    #glEnableVertexAttribArray(3.GLuint)
    #glVertexAttribPointer(3.GLuint, 3, cGL_FLOAT, false, stride, cast[pointer](offset))
    #offset += 3 * sizeof(float32)

    #glEnableVertexAttribArray(4.GLuint)
    #glVertexAttribPointer(4.GLuint, 3, cGL_FLOAT, false, stride, cast[pointer](offset))

    # Streams data
    if len(data) > 0:
        let size: GLsizeiptr = (sizeof(data[0]) * data.len).GLsizeiptr
        #glBufferData(GL_ARRAY_BUFFER, size, cast[pointer](data[0].caddr), bufferMode)

    glGenBuffers(1, result.modelBufferObject.addr)
    glBindBuffer(GL_ARRAY_BUFFER, result.modelBufferObject)
    for start in 3..6:
        glVertexAttribPointer(
            start.GLuint,
            4,
            cGL_FLOAT,
            false,
            bufferSizeOf.GLsizei,
            cast[pointer]((start - 3) * VECTOR4F_SIZE_BYTES)
        );
        glVertexAttribDivisor(start.GLuint, 1);
        glEnableVertexAttribArray(start.GLuint);

    glGenBuffers(1, result.materialBufferObject.addr)
    glBindBuffer(GL_ARRAY_BUFFER, result.materialBufferObject)
    glVertexAttribPointer(
        7.GLuint,
        4,
        cGL_FLOAT,
        false,
        bufferSizeOf.GLsizei,
        cast[pointer](0)
    );
    glVertexAttribDivisor(7.GLuint, 1);
    glEnableVertexAttribArray(7.GLuint);

    glGenBuffers(1, result.spriteBufferObject.addr)
    glBindBuffer(GL_ARRAY_BUFFER, result.spriteBufferObject)
    glVertexAttribPointer(
        8.GLuint,
        4,
        cGL_FLOAT,
        false,
        bufferSizeOf.GLsizei,
        cast[pointer](0)
    );
    glVertexAttribDivisor(8.GLuint, 1);
    glEnableVertexAttribArray(8.GLuint);

    # Releases the bound vertex array
    glBindVertexArray(0)
    glBindBuffer(GL_ARRAY_BUFFER, 0)

    result.count = data.len.GLsizei
    echo &"Mesh with [{result.count / 3}] faces created."

    add(cache, result)

proc newMesh*(vertices: var openArray[float32], 
              normals: var openArray[float32], 
              uvs: var openArray[float32], 
              indices: openArray[uint32], 
              drawMode: GLenum = GL_TRIANGLES, 
              bufferMode: GLenum = GL_STATIC_DRAW): Mesh =
    var data = newSeq[Vertex]()
    var vIndex = 0
    var uIndex = 0
    while vIndex < len(vertices):
        add(data, 
            Vertex(
                position: vec3(vertices[vIndex], vertices[vIndex + 1], vertices[vIndex] + 2),
                normal: vec3(normals[vIndex], normals[vIndex + 1], normals[vIndex] + 2),
                uv: vec2(uvs[uIndex], uvs[uIndex + 1])
            )
        )
        uIndex += 2
        vIndex += 3
    result = newMesh(data, indices, drawMode, bufferMode)

proc newMesh*(data: var openArray[Vertex], drawMode: GLenum = GL_TRIANGLES, bufferMode: GLenum = GL_STATIC_DRAW): Mesh =
    var indices = newSeq[uint32]() 
    result = newMesh(data, indices, drawMode, bufferMode) 


proc newLinesMesh*(data: var openArray[Vertex], strip: bool = false,
        dynamic: bool = false): Mesh =
    let bufferMode = if dynamic: GL_STREAM_DRAW else: GL_STATIC_DRAW
    let drawMode = if strip: GL_LINE_STRIP else: GL_LINES
    result = newMesh(data, drawMode, bufferMode)


proc newMeshStrip*(data: var openArray[Vertex]): Mesh = newMesh(data, drawMode = GL_TRIANGLE_STRIP)
proc hash*(o: Mesh): Hash = o.vertexBufferObject.int

proc update*(o: Mesh, data: var openArray[Vertex]) =
    if o.bufferMode == GL_STATIC_DRAW:
        quit("Cannot update static mesh.")

    o.count = len(data).GLsizei
    glBindBuffer(GL_ARRAY_BUFFER, o.vertexBufferObject)
    glBufferData(GL_ARRAY_BUFFER, sizeof(data[0]) * len(data), data[0].caddr, o.bufferMode)


proc render*(mesh: Mesh, model: ptr float32, material: ptr uint32, sprite: ptr float32, count: int) =
    glBindVertexArray(mesh.vertexArrayObject)

    glBindBuffer(GL_ARRAY_BUFFER, mesh.modelBufferObject)
    glBufferData(GL_ARRAY_BUFFER, count * bufferSizeOf, model, GL_DYNAMIC_DRAW)

    glBindBuffer(GL_ARRAY_BUFFER, mesh.materialBufferObject)
    glBufferData(GL_ARRAY_BUFFER, count * bufferSizeOf, material, GL_DYNAMIC_DRAW)

    glBindBuffer(GL_ARRAY_BUFFER, mesh.spriteBufferObject)
    glBufferData(GL_ARRAY_BUFFER, count * bufferSizeOf, sprite, GL_DYNAMIC_DRAW)

    if len(mesh.indices) > 0:
        if count > 1:
            glDrawElementsInstanced(mesh.drawMode, len(mesh.indices).GLsizei, GL_UNSIGNED_INT, addr mesh.indices[0], count.GLsizei) 
        else:
            glDrawElements(mesh.drawMode, len(mesh.indices).GLsizei, GL_UNSIGNED_INT, addr mesh.indices[0]) 
    else:
        if count > 1:
            glDrawArraysInstanced(mesh.drawMode, 0, mesh.count, count.GLsizei)
        else:
            glDrawArrays(mesh.drawMode, 0, mesh.count)

    glBindBuffer(GL_ARRAY_BUFFER, 0)

proc destroy*(mesh: Mesh) = remove(cache, mesh)
proc cleanupMeshes*() =
    if len(cache) > 0:
        echo &"Cleaning up [{len(cache)}] meshes..."
        clear(cache)
