import sequtils
import hashes

import ports/opengl
import utils
import container


type
    Vertex* = array[18, float32]
    Mesh* = ref object
        vertexArrayObject: GLuint
        vertexBufferObject: GLuint
        modelBufferObject: GLuint
        materialBufferObject: GLuint
        spriteBufferObject: GLuint
        skinBufferObject: GLuint
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
        glDeleteBuffers(1, mesh.skinBufferObject.addr)
        glDeleteBuffers(1, mesh.spriteBufferObject.addr)
        glDeleteBuffers(1, mesh.materialBufferObject.addr)
        glDeleteBuffers(1, mesh.modelBufferObject.addr)
        glDeleteVertexArrays(1, mesh.vertexArrayObject.addr)
        glDeleteBuffers(1, mesh.vertexBufferObject.addr)

        mesh.skinBufferObject = 0
        mesh.spriteBufferObject = 0
        mesh.materialBufferObject = 0
        mesh.modelBufferObject = 0
        mesh.vertexArrayObject = 0
        mesh.vertexBufferObject = 0

var cache = newCachedContainer[Mesh](destroyMesh)

var bufferSizeOf: int = 0 # Drawable size as stride

proc setBufferSizeOf*(size: int) = bufferSizeOf = size

template loadData(v: var Vertex, buffer: openArray[float32], index: var int, offset, count: int) = 
    if len(buffer) > 0:
        for i in 0..count - 1:
            v[offset + i] = buffer[index]
            inc(index)

template `position`*(v: Vertex): Vec3 = vec3(v[0], v[1], v[2])
template `normal`*(v: Vertex): Vec3 = vec3(v[3], v[4], v[5])
template `uv0`*(v: Vertex): Vec2 = vec2(v[6], v[7])
template `uv1`*(v: Vertex): Vec2 = vec2(v[8], v[9])
template `joint`*(v: Vertex): Vec4 = vec4(v[10], v[11], v[12], v[13])
template `weight`*(v: Vertex): Vec4 = vec4(v[14], v[15], v[16], v[17])

template `position=`*(v: var Vertex, value: Vec3) = 
    v[0] = value.x
    v[1] = value.y
    v[2] = value.z

template `normal=`*(v: var Vertex, value: Vec3) = 
    v[3] = value.x
    v[4] = value.y
    v[5] = value.z


template `uv0=`*(v: var Vertex, value: Vec2) = 
    v[6] = value.x
    v[7] = value.y

template `uv1=`*(v: var Vertex, value: Vec2) = 
    v[8] = value.x
    v[9] = value.y


template `joint=`*(v: var Vertex, value: Vec4) = 
    v[10] = value.x
    v[11] = value.y
    v[12] = value.z
    v[13] = value.w

template `weight=`*(v: var Vertex, value: Vec4) = 
    v[14] = value.x
    v[15] = value.y
    v[16] = value.z
    v[17] = value.w

proc loadPosition(v: var Vertex, buffer: openArray[float32], index: var int) = loadData(v, buffer, index, 0, 3)
proc loadNormal(v: var Vertex, buffer: openArray[float32], index: var int) = loadData(v, buffer, index, 3, 3)
proc loadUv0(v: var Vertex, buffer: openArray[float32], index: var int) = loadData(v, buffer, index, 6, 2)
proc loadUv1(v: var Vertex, buffer: openArray[float32], index: var int) = loadData(v, buffer, index, 8, 2)
proc loadJoint(v: var Vertex, buffer: openArray[float32], index: var int) = loadData(v, buffer, index, 10, 4)
proc loadWeight(v: var Vertex, buffer: openArray[float32], index: var int) = loadData(v, buffer, index, 14, 4)

func newVertex*(position:Vec3): Vertex =
    result.position = position

func newVertex*(position: Vec3, normal:Vec3, uv0: Vec2): Vertex =
    result.position = position
    result.normal = normal
    result.uv0 = uv0

func caddr*(v: var Vertex): ptr float32 = v[0].addr
func `$`*(v: Mesh): string = &"Vertices: [{v.count / 3}] triangles"

proc createAttribute[T](index, offset: var int, dataType: GLenum, count: int) =
    const stride = sizeof(Vertex).GLsizei
    glEnableVertexAttribArray(index.GLuint)
    glVertexAttribPointer(index.GLuint, count.GLint, dataType, false, stride.GLsizei, cast[pointer](offset))
    offset += count * sizeof(T)
    inc(index)

proc createPointerAttribute[T](index: var int, offset: int, dataType: GLenum, count, stride: int) =
    glVertexAttribPointer(index.GLuint, count.GLint, dataType, false, stride.GLsizei, cast[pointer](offset * count * sizeof(T)));
    glVertexAttribDivisor(index.GLuint, 1);
    glEnableVertexAttribArray(index.GLuint);    
    inc(index)

proc newMesh*(data: var openArray[Vertex], 
              indices: openArray[uint32], 
              drawMode: GLenum = GL_TRIANGLES, 
              bufferMode: GLenum = GL_STATIC_DRAW): Mesh =
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
    var 
        offset = 0
        index = 0

    # Sets first vertex attribute array enabled
    createAttribute[float32](index, offset, cGL_FLOAT, 3)
    createAttribute[float32](index, offset, cGL_FLOAT, 3)
    createAttribute[float32](index, offset, cGL_FLOAT, 4)
    createAttribute[float32](index, offset, cGL_FLOAT, 4)
    createAttribute[float32](index, offset, cGL_FLOAT, 4)

    # Streams data
    if len(data) > 0:
        let size: GLsizeiptr = (sizeof(Vertex) * data.len).GLsizeiptr
        glBufferData(GL_ARRAY_BUFFER, size, cast[pointer](data[0].caddr), bufferMode)

    glGenBuffers(1, result.modelBufferObject.addr)
    glBindBuffer(GL_ARRAY_BUFFER, result.modelBufferObject)
    createPointerAttribute[float32](index, 0, cGL_FLOAT, 4, bufferSizeOf)
    createPointerAttribute[float32](index, 1, cGL_FLOAT, 4, bufferSizeOf)
    createPointerAttribute[float32](index, 2, cGL_FLOAT, 4, bufferSizeOf)
    createPointerAttribute[float32](index, 3, cGL_FLOAT, 4, bufferSizeOf)

    glGenBuffers(1, result.materialBufferObject.addr)
    glBindBuffer(GL_ARRAY_BUFFER, result.materialBufferObject)
    createPointerAttribute[uint32](index, 0, cGL_FLOAT, 4, bufferSizeOf)

    glGenBuffers(1, result.spriteBufferObject.addr)
    glBindBuffer(GL_ARRAY_BUFFER, result.spriteBufferObject)
    createPointerAttribute[float32](index, 0, cGL_FLOAT, 4, bufferSizeOf)

    glGenBuffers(1, result.skinBufferObject.addr)
    glBindBuffer(GL_ARRAY_BUFFER, result.skinBufferObject)
    createPointerAttribute[float32](index, 0, cGL_FLOAT, 4, bufferSizeOf)

    # Releases the bound vertex array
    glBindVertexArray(0)
    glEnableVertexAttribArray(0)
    glBindBuffer(GL_ARRAY_BUFFER, 0)

    result.count = data.len.GLsizei
    echo &"Mesh with [{result.count}] indices created."

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

proc newMesh*(vertices,
              normals, 
              uvs0,
              uvs1,
              joints,
              weights: var openArray[float32], 
              indices: openArray[uint32], 
              drawMode: GLenum = GL_TRIANGLES, 
              bufferMode: GLenum = GL_STATIC_DRAW): Mesh =
    var 
        data = newSeq[Vertex](vertices.len div 3)
        index = 0
        vIndex = 0
        nIndex = 0
        uIndex0 = 0
        uIndex1 = 0
        jIndex = 0
        wIndex = 0
    while vIndex < len(vertices):
        loadPosition(data[index], vertices, vIndex)
        loadNormal(data[index], normals, nIndex)
        loadUv0(data[index], uvs0, uIndex0)
        loadUv1(data[index], uvs1, uIndex1)
        loadJoint(data[index], joints, jIndex)
        loadWeight(data[index], weights, wIndex)
        inc(index)

    if drawMode == GL_TRIANGLES and len(normals) == 0:
        recalculateNormals(data)

    result = newMesh(data, indices, drawMode, bufferMode)

proc newMesh*(vertices,
              normals, 
              uvs,
              joints,
              weights: var openArray[float32],
              indices: openArray[uint32], 
              drawMode: GLenum = GL_TRIANGLES, 
              bufferMode: GLenum = GL_STATIC_DRAW): Mesh =
    var 
        data = newSeq[Vertex](vertices.len div 3)
        index = 0
        vIndex = 0
        nIndex = 0
        uIndex = 0
        jIndex = 0
        wIndex = 0
    while vIndex < len(vertices):
        loadPosition(data[index], vertices, vIndex)
        loadNormal(data[index], normals, nIndex)
        loadUv0(data[index], uvs, uIndex)
        loadJoint(data[index], joints, jIndex)
        loadWeight(data[index], weights, wIndex)
        inc(index)

    if drawMode == GL_TRIANGLES and len(normals) == 0:
        recalculateNormals(data)

    result = newMesh(data, indices, drawMode, bufferMode)

proc newMesh*(vertices,
              normals, 
              uvs: openArray[float32],
              indices: openArray[uint32], 
              drawMode: GLenum = GL_TRIANGLES, 
              bufferMode: GLenum = GL_STATIC_DRAW): Mesh =
    var 
        data = newSeq[Vertex](vertices.len div 3)
        index = 0
        vIndex = 0
        nIndex = 0
        uIndex = 0
    while vIndex < len(vertices):
        loadPosition(data[index], vertices, vIndex)
        loadNormal(data[index], normals, nIndex)
        loadUv0(data[index], uvs, uIndex)
        inc(index)

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

proc render*(mesh: Mesh, model: ptr float32, material: ptr uint32, sprite: ptr float32, skin: ptr float32, count: int) =
    glBindVertexArray(mesh.vertexArrayObject)

    glBindBuffer(GL_ARRAY_BUFFER, mesh.modelBufferObject)
    glBufferData(GL_ARRAY_BUFFER, (count * bufferSizeOf).GLsizeiptr, model, GL_DYNAMIC_DRAW)

    glBindBuffer(GL_ARRAY_BUFFER, mesh.materialBufferObject)
    glBufferData(GL_ARRAY_BUFFER, (count * bufferSizeOf).GLsizeiptr, material, GL_DYNAMIC_DRAW)

    glBindBuffer(GL_ARRAY_BUFFER, mesh.spriteBufferObject)
    glBufferData(GL_ARRAY_BUFFER, (count * bufferSizeOf).GLsizeiptr, sprite, GL_DYNAMIC_DRAW)

    glBindBuffer(GL_ARRAY_BUFFER, mesh.skinBufferObject)
    glBufferData(GL_ARRAY_BUFFER, (count * bufferSizeOf).GLsizeiptr, skin, GL_DYNAMIC_DRAW)

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
