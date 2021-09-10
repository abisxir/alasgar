import math
import ../core
import ../utils

var sphereMesh: Mesh

proc createSphereMesh(): Mesh =
    var vertexes = newSeq[Vertex]()

    var 
        x, y, z, xy, nx, ny, nz, uvx, uvy, sectorAngle, stackAngle: float32

    const sectorCount = 16
    const stackCount = 16
    const radius = 1.0    
    const lengthInv = 1.0.float32 / radius
    
    const sectorStep: float32 = 2 * PI / sectorCount
    const stackStep: float32 = PI / stackCount

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

            vertexes.add(Vertex(position: vec3(x, y, z), normal: vec3(nx, ny, nz), uv: vec2(uvx, uvy)))

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

proc newSphereMesh*(): MeshComponent =
    new(result)
    if sphereMesh == nil:
        sphereMesh = createSphereMesh()
    result.instance = sphereMesh
