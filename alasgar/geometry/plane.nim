import tables

import ../core
import ../utils

var cache = initTable[(uint32, uint32, int, int), Mesh]()

proc generatePlaneMesh(rows, cols: uint32, vertices: var seq[Vertex], indices: var seq[uint32]) =
    for i in 0..rows: 
        for j in 0..cols:
            var v: Vertex
            v.position = vec3(
                j.float32 / cols.float32 - 0.5, 
                0.0,
                i.float32 / rows.float32 - 0.5
            )
            v.normal = vec3(0.0, 1.0, 0.0)
            add(vertices, v)
            
    for i in 0..<rows:
        for j in 0..<cols:
            let index = (i * (cols + 1)) + j

            indices.add(index)
            indices.add(index + 1)
            indices.add(index + cols + 1)

            indices.add(index + 1)
            indices.add(index + cols + 2)
            indices.add(index + cols + 1)
   
    for i in vertices.low..vertices.high: 
        vertices[i].normal = VEC3_UP

proc createPlaneMesh(width, height: uint32): Mesh =
    var 
        vertices: seq[Vertex]
        indices: seq[uint32]
    generatePlaneMesh(width, height, vertices, indices)
    result = newMesh(vertices, indices)


#[
proc createPlaneMesh(width, height: float32, vSectors, hSectors: int) = 
    let xoffset = -width 
    let yoffset = -height
    let lx = (width * 2) / vSectors.float32
    let ly = (height * 2) / hSectors.float32
    let normal = vec3(0, 1, 0)
    var vertexes = newSeq[Vertex]()

    for j in 0..hSectors - 1:
        let ty = yoffset + ly * j.float32
        for i in 0..vSectors - 1:
            let tx = xoffset + lx * i.float32
            vertexes.add(Vertex(position=vec3(tx + lx, 0, ty), normal: normal, uv=vec2(1, 0)))
            vertexes.add(Vertex(position=vec3(tx, 0, ty + ly), normal: normal, uv=vec2(0, 1)))
            vertexes.add(Vertex(position=vec3(tx, 0, ty), normal: normal, uv=vec2(0, 0)))

            vertexes.add(Vertex(position=vec3(tx + lx, 0, ty), normal: normal, uv=vec2(1, 0)))
            vertexes.add(Vertex(position=vec3(tx, 0, ty + ly), normal: normal, uv=vec2(0, 1)))
            vertexes.add(Vertex(position=vec3(tx + lx, 0, ty + ly), normal: normal, uv=vec2(1, 1)))
    
    meshes[(width, height, vSectors, hSectors)] = newMesh(vertexes)
]#

proc plane1x1(): Mesh = 
    var 
        vertices = [
            newVertex(position=vec3(-0.5, 0.0, 0.5), normal=VEC3_UP, uv0=vec2(0, 0)),
            newVertex(position=vec3(-0.5, 0, -0.5), normal=VEC3_UP, uv0=vec2(0, 1)),
            newVertex(position=vec3(0.5, 0, -0.5), normal=VEC3_UP, uv0=vec2(1, 1)),
            newVertex(position=vec3(0.5, 0, 0.5), normal=VEC3_UP, uv0=vec2(1, 0)),
        ]
        indices = [
            0.uint32, 1, 2,
            0, 2, 3
        ]
    result = newMesh(vertices, indices)


proc newPlane(width, height: uint32): Mesh =
    if not cache.hasKey((width, height, 1, 1)):
        if width == 1 and height == 1:
            cache[(width, height, 1, 1)] = plane1x1()
        else:
            cache[(width, height, 1, 1)] = createPlaneMesh(width, height)
    result = cache[(width, height, 1, 1)]

proc newPlaneMesh*(width=1.uint32, height=1.uint32): MeshComponent = 
    var instance = newPlane(width, height)
    result = newMeshComponent(instance)
