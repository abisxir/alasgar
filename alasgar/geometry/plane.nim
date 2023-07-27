import tables

import ../core
import ../utils

var cache = initTable[(uint32, uint32, int, int), Mesh]()

#include <vector>
#include <glm/glm.hpp>

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

            # Compute and add the normal vectors for each triangle
            var 
                v1 = vertices[index]
                v2 = vertices[index + 1]
                v3 = vertices[index + cols + 1]
                edge1 = v2.position - v1.position
                edge2 = v3.position - v1.position
                normal = normalize(cross(edge1, edge2))

            vertices[index].normal = vertices[index].normal + normal
            vertices[index + 1].normal = vertices[index + 1].normal + normal
            vertices[index + cols + 1].normal = vertices[index + cols + 1].normal + normal

            edge1 = v3.position - v2.position
            edge2 = vertices[index + cols + 2].position - v2.position
            normal = normalize(cross(edge1, edge2))

            vertices[index + 1].normal = vertices[index + 1].normal + normal
            vertices[index + cols + 2].normal = vertices[index + cols + 2].normal + normal
            vertices[index + cols + 1].normal = vertices[index + cols + 1].normal + normal
   
    for i in vertices.low..vertices.high: 
        vertices[i].normal = normalize(vertices[i].normal);

proc createPlaneMesh(width, height: uint32) =
    var 
        vertices: seq[Vertex]
        indices: seq[uint32]
    generatePlaneMesh(width, height, vertices, indices)
    cache[(width, height, 1, 1)] = newMesh(vertices, indices)
    
    #var vertices = [
    #    newVertex(position=vec3(width, -height, 0), normal=vec3(0, 0, 1), uv0=vec2(1, 0)), 
    #    newVertex(position=vec3(width, height, 0), normal=vec3(0, 0, 1), uv0=vec2(1, 1)),
    #    newVertex(position=vec3(-width, -height, 0), normal=vec3(0, 0, 1), uv0=vec2(0, 0)),
    #    newVertex(position=vec3(-width, height, 0), normal=vec3(0, 0, 1), uv0=vec2(0, 1)),
    #]
    #meshes[(width, height, 1, 1)] = newMeshStrip(vertices)


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

proc newPlane(width, height: uint32): Mesh =
    if not cache.hasKey((width, height, 1, 1)):
        createPlaneMesh(width, height)
    result = cache[(width, height, 1, 1)]

proc newPlaneMesh*(width, height: uint32): MeshComponent = 
    var instance = newPlane(width, height)
    result = newMeshComponent(instance)
