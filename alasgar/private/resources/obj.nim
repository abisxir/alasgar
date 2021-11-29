import streams
import strutils
import strformat

import ../core
import ../assets
import ../utils
import model
import resource

export resource, model

proc openObjFile(filename: string): Stream =
    result = openAssetStream(filename)

    if isNil(result):
        raise newAlasgarError(&"Could not open file [{filename}]!")

proc extractFilename(buf: string): string = 
    let remained = filterIt(split(buf, " "), isFilename(it))
    result = if len(remained) > 0: remained[^1] else: ""

proc extractName(buf: string): string = 
    let remained = filterIt(split(buf, " "), not isEmptyOrWhitespace(it))
    result = if len(remained) > 0: strip(remained[^1]) else: ""

proc getFilename(fullpath: string): string = filterIt(split(fullpath, "/"), not isEmptyOrWhitespace(it))[^1]
proc makeFileName(fullpath, filename: string): string = replace(fullpath, getFilename(fullpath), filename)
proc readFloats(buf: string): seq[float32] =
    let vs = filterIt(buf.split(" "), not isEmptyOrWhitespace(it))
    result = mapIt(vs, parseFloat(it).float32)

proc readFloat2(buf: string): (float32, float32) =
    let vs = filterIt(buf.split(" "), not isEmptyOrWhitespace(it))
    result = (parseFloat(vs[1]).float32, parseFloat(vs[2]).float32)

proc readFloat3(buf: string): (float32, float32, float32) =
    let vs = filterIt(buf.split(" "), not isEmptyOrWhitespace(it))
    result = (parseFloat(vs[1]).float32, parseFloat(vs[2]).float32, parseFloat(vs[2]).float32)

proc readColor(buf: string): Color = 
    let (r, g, b) = readFloat3(buf)
    result = color(r, g, b)

proc readVec3(buf: string): Vec3 =
    let (x, y, z) = readFloat3(buf)
    result = vec3(x, y, z)

proc readVec2(buf: string): Vec2 =
    let (x, y) = readFloat2(buf)
    result = vec2(x, y)

proc loadTexture(modelFileName, buf: string, mr: ModelResource): Texture =
    let relativeName = extractFilename(buf)
    let imageFilename = makeFileName(modelFileName, relativeName)
    result = newTexture(imageFilename)
    addTexture(mr, result)

proc loadMaterials(modelFileName: string, materialFileName: string, mr: ModelResource) =
    let 
        filename = makeFileName(modelFileName, materialFileName)
        file = openObjFile(filename)
    var 
        buf = ""
        materialName = ""
    while readLine(file, buf):
        if startsWith(buf, "newmtl"):
            materialName = extractName(buf)
            if not isEmptyOrWhitespace(materialName):
                discard addMaterial(mr, materialName)
        elif not isEmptyOrWhitespace(materialName):
            let material = getMaterial(mr, materialName)
            if startsWith(buf, "Kd"):
                material.diffuseColor = readColor(buf)
            elif startsWith(buf, "Ks"):
                material.specularColor = readColor(buf)
            elif startsWith(buf, "map_Kd"):
                material.diffuseTexture = loadTexture(modelFileName, buf, mr)
            elif startsWith(buf, "bump") or startsWith(buf, "map_bump"):
                material.normalTexture = loadTexture(modelFileName, buf, mr)

proc loadObj*(filename: string): Resource =
    var 
        fileStream = openObjFile(filename) 
        buf = ""
        verticesCache = newSeq[Vec3]()
        uvCache = newSeq[Vec2]()
        normalsCache = newSeq[Vec3]()
        vertices = newSeq[Vertex]()
        modelName = ""
        modelResource = new(ModelResource)
    
    result = modelResource

    proc makeFromCache(vtx: seq[string]): Vertex = 
        let vi = parseInt(vtx[0]).uint32 - 1
        result.position = verticesCache[vi]

        let ti = parseInt(vtx[1]) - 1
        result.uv = uvCache[ti]

        let ni = parseInt(vtx[2]) - 1
        result.normal = normalsCache[ni]

    while fileStream.readLine(buf):
        if startsWith(buf, "mtllib "):
            let materialFileName = extractFilename(buf)
            loadMaterials(filename, materialFileName, modelResource)
        elif startsWith(buf, "o "):
            if len(vertices) > 0 and not isEmptyOrWhitespace(modelName):
                discard addMesh(modelResource, modelName, vertices)
                vertices = newSeq[Vertex]()
                #clear(verticesCache)
                #clear(normalsCache)
                #clear(uvCache)
            modelName = extractName(buf)
            echo &"Model[{modelName}] is loading..."
            let node = addNode(modelResource, name=modelName, parent="", position=VEC3_ZERO, rotation=VEC3_ZERO, scale=VEC3_ONE)
            node.mesh = modelName
        else:
            if startsWith(buf, "usemtl ") and hasNode(modelResource, modelName):
                let node = getNode(modelResource, modelName)
                node.material = extractName(buf)
                echo &"Setting material[{node.material}] to model[{modelName}]."
            elif buf.startsWith("v "):
                verticesCache.add(readVec3(buf))
            elif buf.startsWith("vt"):
                uvCache.add(readVec2(buf))
            elif buf.startsWith("vn"):
                let normal = readVec3(buf)
                normalsCache.add(normal)
            elif buf.startsWith("f "):
                let fs = buf.split(" ")
                let v0 = makeFromCache(fs[1].split("/"))
                add(vertices, v0)
                let v1 = makeFromCache(fs[2].split("/"))
                add(vertices, v1)
                let v2 = makeFromCache(fs[3].split("/"))
                add(vertices, v2)

    if len(vertices) > 0 and not isEmptyOrWhitespace(modelName):
        discard addMesh(modelResource, modelName, vertices)

registerResourceManager("obj", loadObj, destroyModel)
