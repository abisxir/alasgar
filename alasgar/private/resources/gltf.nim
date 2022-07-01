import streams
import strutils
import strformat
import json
import options
import base64
import os
import tables

import ../core
import ../assets
import ../utils
import model
import resource

export resource, model

type
    NormalizeFunction[T] = proc(o: T): T
    FilterType = enum
        filterTypeNearst = 9728
        filterTypeLinear = 9729
        filterTypeNearstMipmapNearst = 9984
        filterTypeLinearMipmapNearst = 9985
        filterTypeNearstMipmapLinear = 9986
        filterTypeLinearMipmapLinear = 9987
        filterTypeRepeat = 10497
        filterTypeClampToEdge = 33071
        filterTypeMirroredRepeat = 33648
    ComponentType = enum
        typeI8 = 5120
        typeUI8 = 5121
        typeI16 = 5122
        typeUI16 = 5123
        typeUI32 = 5125
        typeF32 = 5126
    DrawMode = enum
        drawModePoints = 0
        drawModeLines = 1
        drawModeLineLoop = 2
        drawModeLineStrip = 3
        drawModeTriangles = 4
        drawModeTriangleStrip = 5
        drawModeTriangleFan = 6
    Asset = object
        generator: Option[string]
        version: Option[string]
    Accessor = object
        bufferView: Option[int]
        byteOffset: Option[int]
        componentType: int
        count: int
        max: Option[seq[float]]
        min: Option[seq[float]]
        `type`: string
    Buffer = object
        byteLength: int
        uri: string
        data: Option[seq[uint8]]
    BufferView = object
        buffer: int
        byteOffset: Option[int]
        byteLength: int
        byteStride: Option[int]
        target: Option[int]
    Scene = object
        nodes: seq[int]
    Node = object
        children: Option[seq[int]]
        matrix: Option[array[16, float32]]
        translation: Option[array[3, float32]]
        rotation: Option[array[4, float32]]
        scale: Option[array[3, float32]]
        mesh: Option[int]
        name: Option[string]
    Attributes = object
        POSITION: Option[int]
        NORMAL: Option[int]
        TANGENT: Option[int]
        TEXCOORD_0: Option[int]
        COLOR_0: Option[int]
        JOINTS_0: Option[int]
        WEIGHTS_0: Option[int]
    Primitive = object
        attributes: Attributes
        indices: Option[int]
        mode: Option[int]
        material: Option[int]
        name: Option[string]
    MeshDef = object
        name: Option[string]
        primitives: seq[Primitive]
    SamplerProps = object
        magFilter: Option[int]
        minFilter: Option[int]
        wrapS: Option[int]
        wrapT: Option[int]
    Sampler = object
        index: int
        scale: Option[float32]
        texCoord: Option[int]
    MaterialRougness = object
        baseColorTexture: Option[Sampler]
        metallicRoughnessTexture: Option[Sampler]
        baseColorFactor: Option[array[4, float32]]
        metallicFactor: Option[float32]
        roughnessFactor: Option[float32]
    Material = object
        pbrMetallicRoughness: Option[MaterialRougness]
        normalTexture: Option[Sampler]
        occlusionTexture: Option[Sampler]
        emissiveTexture: Option[Sampler]
        emissiveFactor: Option[array[3, float32]]
        name: Option[string]
    TextureDef = object
        sampler: Option[int]
        source: Option[int]
    ImageDef = object
        uri: Option[string]
        mimeType: Option[string]
        bufferView: Option[int]
    Document = object
        asset: Option[Asset]
        scene: Option[int]
        scenes: seq[Scene]
        buffers: seq[Buffer]
        bufferViews: seq[BufferView]
        meshes: seq[MeshDef]
        nodes: seq[Node]
        accessors: seq[Accessor]
        extensionsRequired: Option[seq[string]]
        materials: Option[seq[Material]]
        textures: Option[seq[TextureDef]]
        images: Option[seq[ImageDef]]
        samplers: Option[seq[SamplerProps]]
        filename: Option[string]

proc `path`(document: Document): string = splitFile(document.filename.get).dir
proc toColor(v: array[4, float32]): Color = color(v[0], v[1], v[2], v[3])
proc toColor(v: array[3, float32]): Color = color(v[0], v[1], v[2], 1)
        
proc toTextureParams(document: Document, sampler: Option[int]): (GLenum, GLenum, GLenum, GLenum, GLenum) =
    var 
        wrapT = GL_REPEAT 
        wrapS = GL_REPEAT 
        minFilter = GL_NEAREST 
        magFilter = GL_NEAREST

    if sampler.isSome:
        let props = document.samplers.get[sampler.get]
        if props.wrapT.isSome:
            wrapT = case props.wrapT.get.FilterType:
                of filterTypeClampToEdge: GL_CLAMP_TO_EDGE
                of filterTypeRepeat: GL_REPEAT
                of filterTypeMirroredRepeat: GL_MIRRORED_REPEAT
                else: GL_CLAMP_TO_EDGE
        if props.wrapS.isSome:
            wrapS = case props.wrapT.get.FilterType:
                of filterTypeClampToEdge: GL_CLAMP_TO_EDGE
                of filterTypeRepeat: GL_REPEAT
                of filterTypeMirroredRepeat: GL_MIRRORED_REPEAT
                else: GL_CLAMP_TO_EDGE
        if props.minFilter.isSome:
            minFilter = case props.minFilter.get.FilterType:
                of filterTypeLinear: GL_LINEAR
                of filterTypeLinearMipmapLinear: GL_LINEAR_MIPMAP_LINEAR
                of filterTypeLinearMipmapNearst: GL_LINEAR_MIPMAP_NEAREST
                of filterTypeNearstMipmapLinear: GL_NEAREST_MIPMAP_LINEAR
                of filterTypeNearstMipmapNearst: GL_NEAREST_MIPMAP_NEAREST
                else: GL_NEAREST
        if props.magFilter.isSome:
            magFilter = case props.magFilter.get.FilterType:
                of filterTypeLinear: GL_LINEAR
                of filterTypeLinearMipmapLinear: GL_LINEAR_MIPMAP_LINEAR
                of filterTypeLinearMipmapNearst: GL_LINEAR_MIPMAP_NEAREST
                of filterTypeNearstMipmapLinear: GL_NEAREST_MIPMAP_LINEAR
                of filterTypeNearstMipmapNearst: GL_NEAREST_MIPMAP_NEAREST
                else: GL_NEAREST

    return (wrapT, wrapS, wrapT, minFilter, magFilter)


proc `position`(node: Node): Vec3 =
    if node.translation.isSome:
        result = vec3(node.translation.get)
    elif node.matrix.isSome:
        let m = mat4(node.matrix.get)
        result = pos(m)
    else:
        result = VEC3_ZERO

proc `quat`(node: Node): Quat =
    if node.rotation.isSome:
        let r = node.rotation.get
        result = quat(r[0], r[1], r[2], r[3])
    elif node.matrix.isSome:
        let m = mat4(node.matrix.get)
        result = quat(m)
    else:
        result = quat()

proc getScale(node: Node): Vec3 =
    if node.scale.isSome:
        result = vec3(node.scale.get)
    elif node.matrix.isSome:
        let m = mat4(node.matrix.get)
        result = scale(m)
    else:
        result = VEC3_ONE

func getComponentCount(name: string): int =
    case name:
        of "SCALAR": 1
        of "VEC2": 2
        of "VEC3": 3
        of "VEC4": 4
        of "MAT2": 4
        of "MAT3": 9
        of "MAT4": 16
        else: 0

func getComponentSize(t: int): int =
    case t.ComponentType:
        of typeI8: 1
        of typeUI8: 1
        of typeI16: 2
        of typeUI16: 2
        else: 4

func toGLDrawMode(mode: DrawMode): GLenum =
    result = case mode:
        of drawModePoints: GL_POINTS
        of drawModeLines: GL_LINES
        of drawModeLineLoop: GL_LINE_LOOP
        of drawModeLineStrip: GL_LINE_STRIP
        of drawModeTriangles: GL_TRIANGLES
        of drawModeTriangleStrip: GL_TRIANGLE_STRIP
        of drawModeTriangleFan: GL_TRIANGLE_FAN


proc prepare(document: Document, buffer: var Buffer) =
    var
        data: string
        path = document.path
    if buffer.byteLength > 0 and not isEmptyOrWhitespace(buffer.uri):
        if startsWith(buffer.uri, "data:application/octet-stream;base64,"):
            data = decode(buffer.uri.replace("data:application/octet-stream;base64,", ""))
        elif startsWith(buffer.uri, "data:application/gltf-buffer;base64,"):
            data = decode(buffer.uri.replace("data:application/gltf-buffer;base64,", ""))
        else:
            let filename = &"{path}/{buffer.uri}"
            data = readAsset(filename)
        
        buffer.data = some(cast[seq[uint8]](data))

proc openFile(url: string): Stream =
    result = openAssetStream(url)
    if isNil(result):
        raise newAlasgarError(&"Could not open file [{url}]!")

proc copy[R, O](accessor: Accessor, bufferView: BufferView, buffer: var Buffer, output: var seq[O], normalize: NormalizeFunction[O]=nil) =
    let 
        componentCount = getComponentCount(accessor.`type`)
        count = accessor.count * componentCount
        bufferViewOffset = if bufferView.byteOffset.isSome: bufferView.byteOffset.get else: 0
        accessorOffset = if accessor.byteOffset.isSome: accessor.byteOffset.get else: 0
        offset = bufferViewOffset + accessorOffset
        stride = if bufferView.byteStride.isSome: bufferView.byteStride.get else: sizeof(R) * componentCount
    var 
        data = buffer.data.get
        element = offset
        index = 0

    output.setLen(count)
    while index < count:
        for i in 0..componentCount - 1:
            let r: ptr R = cast[ptr R](addr data[element + i * sizeof(R)])
            output[index] = if isNil(normalize): r[].O else: normalize(r[].O)
            inc(index)
        element += stride

proc getAccessor(document: Document, index: Option[int]): Option[Accessor] =
    if index.isSome:
        result = some(document.accessors[index.get])
    else:
        result = none(Accessor)

proc loadAccessor(document: Document, aIndex: int, output: var seq[float32]) =
    let accessor = document.accessors[aIndex]
    if accessor.bufferView.isSome:
        var 
            bufferView = document.bufferViews[accessor.bufferView.get]
            buffer = document.buffers[bufferView.buffer]
        
        if document.accessors[aIndex].componentType == typeF32.int:
            copy[float32, float32](
                accessor, 
                bufferView, 
                buffer, 
                output
            )
        elif document.accessors[aIndex].componentType == typeUI16.int:
            copy[uint16, float32](
                accessor, 
                bufferView, 
                buffer, 
                output,
                normalize=proc(c: float32): float32 = c / 65535.0
            )
        elif document.accessors[aIndex].componentType == typeI16.int:
            copy[int16, float32](
                accessor, 
                bufferView, 
                buffer, 
                output,
                normalize=proc(c: float32): float32 = max(c / 32767.0, -1.0)
            )
        elif document.accessors[aIndex].componentType == typeUI8.int:
            copy[uint8, float32](
                accessor, 
                bufferView, 
                buffer, 
                output,
                normalize=proc(c: float32): float32 = c / 255.0
            )
        elif document.accessors[aIndex].componentType == typeI8.int:
            copy[int8, float32](
                accessor, 
                bufferView, 
                buffer, 
                output, 
                normalize=proc(c: float32): float32 = max(c / 127.0, -1.0)
            )

proc loadPrimitive(document: Document, primitive: Primitive): Mesh = 
    var
        indices: seq[uint32]
        positions, normals, uvs, joints, weights: seq[float32]

    let indicesAccessor = getAccessor(document, primitive.indices)
    if indicesAccessor.isSome:
        if indicesAccessor.get.bufferView.isSome:
            var 
                bufferView = document.bufferViews[indicesAccessor.get.bufferView.get]
                buffer = document.buffers[bufferView.buffer]
            if indicesAccessor.get.componentType == typeUI16.int:
                copy[uint16, uint32](indicesAccessor.get, bufferView, buffer, indices)
            elif indicesAccessor.get.componentType == typeUI8.int:
                copy[uint8, uint32](indicesAccessor.get, bufferView, buffer, indices)
            elif indicesAccessor.get.componentType == typeUI32.int:
                copy[uint32, uint32](indicesAccessor.get, bufferView, buffer, indices)

    if isSome(primitive.attributes.POSITION):
        let aIndex: int = primitive.attributes.POSITION.get
        loadAccessor(document, aIndex, positions)
    if isSome(primitive.attributes.NORMAL):
        let aIndex: int = primitive.attributes.NORMAL.get
        loadAccessor(document, aIndex, normals)
    if isSome(primitive.attributes.TEXCOORD_0):
        let aIndex: int = primitive.attributes.TEXCOORD_0.get
        loadAccessor(document, aIndex, uvs)

    let drawMode = if primitive.mode.isSome: primitive.mode.get.DrawMode else: drawModeTriangles
    result = newMesh(positions, normals, uvs, indices, drawMode=toGLDrawMode(drawMode))

proc needsDraco(document: Document): bool = document.extensionsRequired.isSome and contains(document.extensionsRequired.get, "KHR_draco_mesh_compression")

proc loadMeshes(document: var Document, model: ModelResource) =
    for i, mesh in mpairs(document.meshes):
        if isNone(mesh.name):
            mesh.name = some(&"mesh-{i}")
        for j, primitive in mpairs(mesh.primitives):
            if isNone(primitive.name):
                primitive.name = some(&"{mesh.name.get}-{i}-{j}")
            discard addMesh(model, primitive.name.get, loadPrimitive(document, primitive))

proc loadTexture(document: Document, sampler: Option[Sampler]): Texture =
    if sampler.isSome and document.textures.isSome:
        if sampler.get.texCoord.isSome and sampler.get.texCoord.get != 0:
            # TODO: check texcoord
            echo "Warning: two texCoord is not supported!"
        let t = document.textures.get[sampler.get.index]
        if t.source.isSome:
            let 
                image = document.images.get[t.source.get]
                (wrapT, wrapS, wrapR, minFilter, magFilter) = toTextureParams(document, t.sampler)

            if image.uri.isSome:
                let uri = if startsWith(image.uri.get, "data:image/"): image.uri.get else: &"{document.path}/{image.uri.get}"
                result = newTexture(uri, wrapT=wrapT, wrapS=wrapS, wrapR=wrapR, minFilter=minFilter, magFilter=magFilter)
            else:
                # TODO: check mimeType and bufferView
                echo "Has buffer instead of image file: ", document.filename
                raise newAlasgarError("Image in buffer is not supported")
                

proc loadMaterials(document: Document, model: ModelResource) =
    if document.materials.isSome:
        for i, m in pairs(document.materials.get):
            let material = addMaterial(model, &"{i}", newMaterialComponent())
            if m.pbrMetallicRoughness.isSome:
                if m.pbrMetallicRoughness.get.baseColorFactor.isSome:
                    material.diffuseColor = toColor(m.pbrMetallicRoughness.get.baseColorFactor.get)
                material.albedoMap = loadTexture(document, m.pbrMetallicRoughness.get.baseColorTexture)
                material.metallicMap = loadTexture(document, m.pbrMetallicRoughness.get.metallicRoughnessTexture)
                material.roughnessMap = material.metallicMap
                material.aoMap = loadTexture(document, m.occlusionTexture)
                material.normalMap = loadTexture(document, m.normalTexture)
                material.emissiveMap = loadTexture(document, m.emissiveTexture)
                material.metallic = if m.pbrMetallicRoughness.get.metallicFactor.isSome: m.pbrMetallicRoughness.get.metallicFactor.get else: 1
                material.roughness = if m.pbrMetallicRoughness.get.roughnessFactor.isSome: m.pbrMetallicRoughness.get.roughnessFactor.get else: 1
                material.emissiveColor = if m.emissiveFactor.isSome: toColor(m.emissiveFactor.get) else: COLOR_BLACK                


proc loadGLTF*(filename: string): Resource =
    var 
        fileStream = openFile(filename)
        json = parseJson(fileStream)
        document = to(json, Document)

    document.filename = some(filename)

    # Closes file when the scope ends
    defer: close(fileStream)

    if needsDraco(document):
        raise newAlasgarError("Draco extension is not sopprted!")

    # Creates data buckets out of buffers
    for buffer in mitems(document.buffers):
        prepare(document, buffer)

    # Creates resource model
    let model = new(ModelResource)

    # Loads all materials
    loadMaterials(document, model)

    # Loads all meshes
    loadMeshes(document, model)

    proc addChildren(parent: string, child: int) =
        let 
            node = document.nodes[child]
            name = if node.name.isSome: node.name.get else: &"node-{child}"
            main = addNode(model, name, parent, node.position, node.quat, getScale(node))
        if node.mesh.isSome:
            let mesh = document.meshes[node.mesh.get]
            if len(mesh.primitives) > 1:
                for p in mesh.primitives:
                    let child = addNode(model, p.name.get, name, VEC3_ZERO, quat(), VEC3_ONE)
                    child.mesh = p.name.get
                    if p.material.isSome:
                        child.material = &"{p.material.get}"
            else:
                main.mesh = mesh.primitives[0].name.get
                if mesh.primitives[0].material.isSome:
                    main.material = &"{mesh.primitives[0].material.get}"

        if node.children.isSome:
            for c in node.children.get:
                addChildren(name, c)

    for i, scene in pairs(document.scenes):
        let name = &"scene-{i}"
        discard addNode(model, name, "", VEC3_ZERO, quat(), VEC3_ONE)
        for child in scene.nodes:
            addChildren(name, child)
    
    result = model

registerResourceManager("gltf", loadGLTF, destroyModel)
