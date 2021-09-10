import streams
import strutils
import strformat
import tables

import ../core
import ../assets
import ../utils


proc loadFromFile(filename: string): Mesh =
    var fileStream = openAssetStream(filename)
    var verticesCache = newSeq[Vec3]()
    var uvCache = newSeq[Vec2]()
    var normalsCache = newSeq[Vec3]()
    #var tangentsCache = newSeq[Vec3]()
    #var biNormalsCache = newSeq[Vec3]()

    var vertixes = newSeq[Vertex]()

    proc addFromCache(vtx: seq[string]): Vertex = 
        let vi = parseInt(vtx[0]).uint32 - 1
        result.position = verticesCache[vi]

        let ti = parseInt(vtx[1]) - 1
        result.uv = uvCache[ti]

        let ni = parseInt(vtx[2]) - 1
        result.normal = normalsCache[ni]

        vertixes.add(result)

    if isNil(fileStream):
        quit &"Could not open file [{filename}]!"
        
    var buf = ""
    while fileStream.readLine(buf):
        if buf.startsWith("v "):
            let vs = buf.split(" ")
            verticesCache.add(vec3(parseFloat(vs[1]).float32, parseFloat(vs[2]).float32, parseFloat(vs[3]).float32))
        elif buf.startsWith("vt"):
            let ts = buf.split(" ")
            uvCache.add(vec2(parseFloat(ts[1]).float32, parseFloat(ts[2]).float32))
        elif buf.startsWith("vn"):
            let ns = buf.split(" ")
            let normal = vec3(parseFloat(ns[1]).float32, parseFloat(ns[2]).float32, parseFloat(ns[3]).float32)
            normalsCache.add(normal)
        #elif buf.startsWith("f "):
            #let fs = buf.split(" ")
            
            #var offset = vertixes.len
            #let v0 = addFromCache(fs[1].split("/"))
            #let v1 = addFromCache(fs[2].split("/"))
            #let v2 = addFromCache(fs[3].split("/"))

            #let deltaPos1 = v1.position - v0.position
            #let deltaPos2 = v2.position - v0.position

            #let deltaUV1 = v1.uv - v0.uv
            #let deltaUV2 = v2.uv - v0.uv

            #let r = 1.0 / (deltaUV1.x * deltaUV2.y - deltaUV1.y * deltaUV2.x)
            #let tangent = normalize((deltaPos1 * deltaUV2.y   - deltaPos2 * deltaUV1.y) * r)
            #let biNormal = normalize((deltaPos2 * deltaUV1.x   - deltaPos1 * deltaUV2.x) * r)

            #vertixes[offset + 0].tangent = tangent
            #vertixes[offset + 0].biNormal = biNormal

            #vertixes[offset + 1].tangent = tangent
            #vertixes[offset + 1].biNormal = biNormal

            #vertixes[offset + 2].tangent = tangent
            #vertixes[offset + 2].biNormal = biNormal


    echo &"number of vertices: {vertixes.len}"
    echo &"number of trangles: {vertixes.len / 3}"

    result = newMesh(vertixes)

    if outFileName.len > 0:
        var fileStream = newFileStream(outFileName, fmWrite)
        fileStream.writeLine &"var vertixes: array[{vertixes.len}, Vertex] = ["
        for v in vertixes:
            fileStream.writeLine &"""   Vertex(position: vec3f({v.position.x}, {v.position.y}, {v.position.z}), 
        normal: vec3f({v.normal.x}, {v.normal.y}, {v.normal.z}), 
        uv: vec2f({v.uv.x}, {v.uv.y})), """
        fileStream.writeLine "]"
        fileStream.close()

proc loadSTL*(filename: string, outFileName: string=""): Mesh =
    if not hasKey(cache, filename):
        cache[filename] = loadObjFromFile(filename, outFileName)
    result = cache[filename]
