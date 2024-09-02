import math
import tables

import ../core
import ../utils

var cache = initTable[(int), Mesh]()

proc createSphereMesh(factor: int): Mesh =
    var 
        vertexes = newSeq[Vertex]()
        x, y, z, xy, nx, ny, nz, uvx, uvy, sectorAngle, stackAngle: float32
    let 
        sectorCount = 32 * factor
        stackCount = 32 * factor
        radius = 1.0    
        lengthInv = 1.0.float32 / radius
        sectorStep: float32 = 2'f32 * PI / sectorCount.float32
        stackStep: float32 = PI / stackCount.float32

    for i in 0..stackCount:
        stackAngle = PI / 2 - i.float32 * stackStep
        xy = radius * cos(stackAngle)
        z = radius * sin(stackAngle)

        for j in 0..sectorCount:
            sectorAngle = j.float32 * sectorStep

            x = xy * cos(sectorAngle)
            y = xy * sin(sectorAngle)

            nx = x * lengthInv
            ny = y * lengthInv
            nz = z * lengthInv

            uvx = (float32)j / sectorCount
            uvy = (float32)i / stackCount

            vertexes.add(newVertex(position=vec3(x, y, z), normal=vec3(nx, ny, nz), uv0=vec2(uvx, uvy)))

    var drawVertexes = newSeq[Vertex]()
    for i in 0..stackCount - 1:
        var k1 = i * (sectorCount + 1)
        var k2 = k1 + sectorCount + 1

        for j in 0..sectorCount - 1:
            if i != 0:
                drawVertexes.add(vertexes[k1])
                drawVertexes.add(vertexes[k2])
                drawVertexes.add(vertexes[k1 + 1])

            if i != stackCount - 1:
                drawVertexes.add(vertexes[k1 + 1])
                drawVertexes.add(vertexes[k2])
                drawVertexes.add(vertexes[k2 + 1])

            inc k1
            inc k2

    result = newMesh(drawVertexes)

proc newSphereMesh*(factor=1): MeshComponent =
    new(result)
    if not hasKey(cache, factor):
        cache[factor] = createSphereMesh(factor)
    result.instance = cache[factor]
