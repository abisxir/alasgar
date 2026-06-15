import streams
import strutils
import strformat
import tables

import ../core
import ../assets
import ../utils
import ../container


var cache = initTable[string, Mesh]()

proc openObjFile(filename: string): Stream =
  result = openAssetStream(filename)
  if isNil(result):
    raise newAlasgarError(&"Could not open file [{filename}]!")

proc readObjModels*(filename: string): seq[string] =
  var
    fileStream = openObjFile(filename)
    buf = ""
  while fileStream.readLine(buf):
    if startsWith(buf, "o "):
      let vs = buf.split(" ")
      add(result, vs[1])

proc readObjVertices*(filename: string, modelName: string): seq[Vertex] =
  var
    fileStream = openObjFile(filename)
    buf = ""
    found = false
    verticesCache = newSeq[Vec3]()
    uvCache = newSeq[Vec2]()
    normalsCache = newSeq[Vec3]()

  proc makeFromCache(vtx: seq[string]): Vertex =
    let
      vi = parseInt(vtx[0]).uint32 - 1
      ti = parseInt(vtx[1]) - 1
      ni = parseInt(vtx[2]) - 1
    result.position = verticesCache[vi]
    result.uv = uvCache[ti]
    result.normal = normalsCache[ni]

  while fileStream.readLine(buf):
    if not found:
      if startsWith(buf, "o "):
        let vs = buf.split(" ")
        found = vs[1] == modelName
    else:
      if startsWith(buf, "o "):
        break
    if buf.startsWith("v "):
      let vs = buf.split(" ")
      verticesCache.add(vec3(parseFloat(vs[1]).float32, parseFloat(vs[
          2]).float32, parseFloat(vs[3]).float32))
    elif buf.startsWith("vt"):
      let ts = buf.split(" ")
      uvCache.add(vec2(parseFloat(ts[1]).float32, parseFloat(ts[2]).float32))
    elif buf.startsWith("vn"):
      let ns = buf.split(" ")
      let normal = vec3(parseFloat(ns[1]).float32, parseFloat(ns[2]).float32,
          parseFloat(ns[3]).float32)
      normalsCache.add(normal)
    elif buf.startsWith("f "):
      let
        fs = buf.split(" ")
        v0 = makeFromCache(fs[1].split("/"))
        v1 = makeFromCache(fs[2].split("/"))
        v2 = makeFromCache(fs[3].split("/"))
      add(result, v0)
      add(result, v1)
      add(result, v2)


proc readObjVertices*(filename: string): seq[Vertex] =
  var models = readObjModels(filename)
  if len(models) == 0:
    raise newAlasgarError(&"Could not find any model inside [{filename}]!")
  result = readObjVertices(filename, models[0])


proc loadObj*(filename: string): Mesh =
  if not hasKey(cache, filename):
    var vertices = readObjVertices(filename)
    echo &"number of vertices: {vertices.len}"
    echo &"number of trangles: {vertices.len / 3}"
    cache[filename] = newMesh(vertices)
  result = cache[filename]
