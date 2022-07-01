import tables

import ../core
import ../utils

var meshes = initTable[(float32, float32, int, int), Mesh]()

proc createPlaneMesh(width, height: float32) =
    var vertices = [
        newVertex(position=vec3(width, -height, 0), normal=vec3(0, 0, 1), uv0=vec2(1, 0)), 
        newVertex(position=vec3(width, height, 0), normal=vec3(0, 0, 1), uv0=vec2(1, 1)),
        newVertex(position=vec3(-width, -height, 0), normal=vec3(0, 0, 1), uv0=vec2(0, 0)),
        newVertex(position=vec3(-width, height, 0), normal=vec3(0, 0, 1), uv0=vec2(0, 1)),
    ]

    meshes[(width, height, 1, 1)] = newMeshStrip(vertices)

#[
proc createPlaneMeshx(width, height: float32) =
    let normal = -VEC3_FORWARD
    var vertices = [
        newVertex(position=vec3(0, 0, 0), normal=normal, uv0=vec2(0, 0)), 
        newVertex(position=vec3(width, 0, 0), normal=normal, uv0=vec2(1, 0)),
        newVertex(position=vec3(0, height, 0), normal=normal, uv0=vec2(0, 1)),
        newVertex(position=vec3(width, height, 0), normal=normal, uv0=vec2(1, 1)),
    ]

    var indices = [
        # lower left triangle
        0.uint32, 2, 1,
        # upper right triangle
        2, 3, 1
    ]        

    meshes[(width, height, 1, 1)] = newMesh(vertices, indices)    

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


proc newPlane(width, height: float32, v, h: int): Mesh =
    if not meshes.hasKey((width, height, v, h)):
        createPlaneMesh(width, height, v, h)
    result = meshes[(width, height, v, h)]
]#

proc newPlane(width, height: float32): Mesh =
    if not meshes.hasKey((width, height, 1, 1)):
        createPlaneMesh(width, height)
    result = meshes[(width, height, 1, 1)]

proc newPlaneMesh*(width, height: float32): MeshComponent = 
    var instance = newPlane(width, height)
    result = newMeshComponent(instance)
