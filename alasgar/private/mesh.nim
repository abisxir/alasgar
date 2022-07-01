import sequtils
import hashes

import ports/opengl
import utils
import container


type
    Vertex* = array[14, float32]
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

template `position`*(v: Vertex): Vec3 = vec3(v[0], v[1], v[2])
template `normal`*(v: Vertex): Vec3 = vec3(v[3], v[4], v[5])
template `tangent`*(v: Vertex): Vec4 = vec4(v[6], v[7], v[8], v[9])
template `uv0`*(v: Vertex): Vec2 = vec2(v[10], v[11])
template `uv1`*(v: Vertex): Vec2 = vec2(v[12], v[13])

template `position=`*(v: var Vertex, value: Vec3) = 
    v[0] = value.x
    v[1] = value.y
    v[2] = value.z

template `normal=`*(v: var Vertex, value: Vec3) = 
    v[3] = value.x
    v[4] = value.y
    v[5] = value.z

template `tangent=`*(v: var Vertex, value: Vec4) = 
    v[6] = value.x
    v[7] = value.y
    v[8] = value.z
    v[9] = value.w

template `uv0=`*(v: var Vertex, value: Vec2) = 
    v[10] = value.x
    v[11] = value.y

template `uv1=`*(v: var Vertex, value: Vec2) = 
    v[12] = value.x
    v[13] = value.y

func newVertex*(position:Vec3): Vertex =
    result.position = position

func newVertex*(position: Vec3, normal:Vec3, uv0: Vec2): Vertex =
    result.position = position
    result.normal = normal
    result.uv0 = uv0

func caddr*(v: var Vertex): ptr float32 = v[0].addr
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
    var stride = sizeof(Vertex).GLsizei

    glEnableVertexAttribArray(0.GLuint)
    glVertexAttribPointer(0.GLuint, 3, cGL_FLOAT, false, stride, cast[pointer](0))
    offset += 3 * sizeof(float32)

    glEnableVertexAttribArray(1.GLuint)
    glVertexAttribPointer(1.GLuint, 3, cGL_FLOAT, false, stride, cast[pointer](offset))
    offset += 3 * sizeof(float32)

    glEnableVertexAttribArray(2.GLuint)
    glVertexAttribPointer(2.GLuint, 4, cGL_FLOAT, false, stride, cast[pointer](offset))
    offset += 4 * sizeof(float32)

    glEnableVertexAttribArray(3.GLuint)
    glVertexAttribPointer(3.GLuint, 4, cGL_FLOAT, false, stride, cast[pointer](offset))

    # Streams data
    if len(data) > 0:
        let size: GLsizeiptr = (sizeof(Vertex) * data.len).GLsizeiptr
        glBufferData(GL_ARRAY_BUFFER, size, cast[pointer](data[0].caddr), bufferMode)

    glGenBuffers(1, result.modelBufferObject.addr)
    glBindBuffer(GL_ARRAY_BUFFER, result.modelBufferObject)
    for start in 4..7:
        glVertexAttribPointer(
            start.GLuint,
            4,
            cGL_FLOAT,
            false,
            bufferSizeOf.GLsizei,
            cast[pointer]((start - 4) * VECTOR4F_SIZE_BYTES)
        );
        glVertexAttribDivisor(start.GLuint, 1);
        glEnableVertexAttribArray(start.GLuint);

    glGenBuffers(1, result.materialBufferObject.addr)
    glBindBuffer(GL_ARRAY_BUFFER, result.materialBufferObject)
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

    glGenBuffers(1, result.spriteBufferObject.addr)
    glBindBuffer(GL_ARRAY_BUFFER, result.spriteBufferObject)
    glVertexAttribPointer(
        9.GLuint,
        4,
        cGL_FLOAT,
        false,
        bufferSizeOf.GLsizei,
        cast[pointer](0)
    );
    glVertexAttribDivisor(9.GLuint, 1);
    glEnableVertexAttribArray(9.GLuint);

    # Releases the bound vertex array
    glBindVertexArray(0)
    glBindBuffer(GL_ARRAY_BUFFER, 0)

    result.count = data.len.GLsizei
    echo &"Mesh with [{result.count / 3}] faces created."

    add(cache, result)

proc recalculateNormals*(vertices: var openArray[Vertex]) =
    if len(vertices) mod 3 == 0:
        var i = 0
        while i < len(vertices):
            let 
                a = vertices[i].position
                b = vertices[i + 1].position
                c = vertices[i + 2].position
                n = normalize((b - a) * (c - a))
            vertices[i].normal = n
            vertices[i + 1].normal = n
            vertices[i + 2].normal = n
            inc(i, 3)

proc recalculateTangents(vertices: var openArray[Vertex]) =
    discard

proc newMesh*(vertices: openArray[float32], 
              normals: openArray[float32], 
              tangents: openArray[float32],
              uvs0: openArray[float32], 
              uvs1: openArray[float32], 
              indices: openArray[uint32], 
              drawMode: GLenum = GL_TRIANGLES, 
              bufferMode: GLenum = GL_STATIC_DRAW): Mesh =
    var data = newSeq[Vertex](vertices.len div 3)
    var index = 0
    var vIndex = 0
    var uIndex0 = 0
    var uIndex1 = 0
    var tIndex = 0
    while vIndex < len(vertices):
        data[index][0] = vertices[vIndex]
        data[index][1] = vertices[vIndex + 1]
        data[index][2] = vertices[vIndex + 2]

        if len(normals) > 0:
            data[index][3] = normals[vIndex]
            data[index][4] = normals[vIndex + 1]
            data[index][5] = normals[vIndex + 2]

        if len(tangents) > 0:
            data[index][6] = tangents[tIndex]
            data[index][7] = tangents[tIndex + 1]
            data[index][8] = tangents[tIndex + 2]
            data[index][9] = tangents[tIndex + 3]

        if len(uvs0) > 0:
            data[index][10] = uvs0[uIndex0]
            data[index][11] = uvs0[uIndex0 + 1]

        if len(uvs1) > 0:
            data[index][12] = uvs0[uIndex1]
            data[index][13] = uvs0[uIndex1 + 1]

        inc(index)
        inc(uIndex0, 2)
        inc(uIndex1, 2)
        inc(vIndex, 3)
        inc(tIndex, 4)

    if drawMode == GL_TRIANGLES and len(normals) == 0:
        recalculateNormals(data)

    result = newMesh(data, indices, drawMode, bufferMode)

proc newMesh*(vertices: var openArray[float32], 
              normals: var openArray[float32], 
              uvs: var openArray[float32], 
              indices: openArray[uint32], 
              drawMode: GLenum = GL_TRIANGLES, 
              bufferMode: GLenum = GL_STATIC_DRAW): Mesh =
    var data = newSeq[Vertex](vertices.len div 3)
    var index = 0
    var vIndex = 0
    var uIndex = 0
    while vIndex < len(vertices):
        data[index][0] = vertices[vIndex]
        data[index][1] = vertices[vIndex + 1]
        data[index][2] = vertices[vIndex + 2]

        if len(normals) > 0:
            data[index][3] = normals[vIndex]
            data[index][4] = normals[vIndex + 1]
            data[index][5] = normals[vIndex + 2]

        if len(uvs) > 0:
            data[index][10] = uvs[uIndex]
            data[index][11] = uvs[uIndex + 1]

        inc(index)
        inc(uIndex, 2)
        inc(vIndex, 3)

    if drawMode == GL_TRIANGLES and len(normals) == 0:
        recalculateNormals(data)

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

    let
        size = (sizeof(data[0]) * len(data)).GLsizeiptr
        pData = cast[pointer](data[0].caddr)

    o.count = len(data).GLsizei
    glBindBuffer(GL_ARRAY_BUFFER, o.vertexBufferObject)
    glBufferData(GL_ARRAY_BUFFER, size, pData, o.bufferMode)

proc render*(mesh: Mesh, model: ptr float32, material: ptr uint32, sprite: ptr float32, count: int) =
    glBindVertexArray(mesh.vertexArrayObject)

    glBindBuffer(GL_ARRAY_BUFFER, mesh.modelBufferObject)
    glBufferData(GL_ARRAY_BUFFER, (count * bufferSizeOf).GLsizeiptr, model, GL_DYNAMIC_DRAW)

    glBindBuffer(GL_ARRAY_BUFFER, mesh.materialBufferObject)
    glBufferData(GL_ARRAY_BUFFER, (count * bufferSizeOf).GLsizeiptr, material, GL_DYNAMIC_DRAW)

    glBindBuffer(GL_ARRAY_BUFFER, mesh.spriteBufferObject)
    glBufferData(GL_ARRAY_BUFFER, (count * bufferSizeOf).GLsizeiptr, sprite, GL_DYNAMIC_DRAW)

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
