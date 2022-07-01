import ../core
import ../utils

var cubeVertices = [
       # Front
       newVertex(position=vec3(-1, -1,  1), uv0=vec2(0, 0), normal=vec3( 0,  0,  1)),
       newVertex(position=vec3( 1, -1,  1), uv0=vec2(1, 0), normal=vec3( 0,  0,  1)),
       newVertex(position=vec3( 1,  1,  1), uv0=vec2(1, 1), normal=vec3( 0,  0,  1)),
       newVertex(position=vec3(-1,  1,  1), uv0=vec2(0, 1), normal=vec3( 0,  0,  1)), 
       # Back
       newVertex(position=vec3(-1, -1, -1), uv0=vec2(1, 0), normal=vec3( 0,  0, -1)),
       newVertex(position=vec3(-1,  1, -1), uv0=vec2(1, 1), normal=vec3( 0,  0, -1)),
       newVertex(position=vec3( 1,  1, -1), uv0=vec2(0, 1), normal=vec3( 0,  0, -1)),
       newVertex(position=vec3( 1, -1, -1), uv0=vec2(0, 0), normal=vec3( 0,  0, -1)),
       # Top
       newVertex(position=vec3(-1,  1, -1), uv0=vec2(0, 1), normal=vec3( 0,  1,  0)),
       newVertex(position=vec3(-1,  1,  1), uv0=vec2(0, 0), normal=vec3( 0,  1,  0)),
       newVertex(position=vec3( 1,  1,  1), uv0=vec2(1, 0), normal=vec3( 0,  1,  0)),
       newVertex(position=vec3( 1,  1, -1), uv0=vec2(1, 1), normal=vec3( 0,  1,  0)),
       # Bottom
       newVertex(position=vec3(-1, -1, -1), uv0=vec2(0, 0), normal=vec3( 0, -1,  0)), 
       newVertex(position=vec3( 1, -1, -1), uv0=vec2(1, 0), normal=vec3( 0, -1,  0)),
       newVertex(position=vec3( 1, -1,  1), uv0=vec2(1, 1), normal=vec3( 0, -1,  0)),
       newVertex(position=vec3(-1, -1,  1), uv0=vec2(0, 1), normal=vec3( 0, -1,  0)),
       # Right
       newVertex(position=vec3( 1, -1, -1), uv0=vec2(1, 0), normal=vec3( 1,  0,  0)),
       newVertex(position=vec3( 1,  1, -1), uv0=vec2(1, 1), normal=vec3( 1,  0,  0)), 
       newVertex(position=vec3( 1,  1,  1), uv0=vec2(0, 1), normal=vec3( 1,  0,  0)),
       newVertex(position=vec3( 1, -1,  1), uv0=vec2(0, 0), normal=vec3( 1,  0,  0)),
       # Left
       newVertex(position=vec3(-1, -1, -1), uv0=vec2(0, 0), normal=vec3(-1,  0,  0)),
       newVertex(position=vec3(-1, -1,  1), uv0=vec2(1, 0), normal=vec3(-1,  0,  0)),
       newVertex(position=vec3(-1,  1,  1), uv0=vec2(1, 1), normal=vec3(-1,  0,  0)),
       newVertex(position=vec3(-1,  1, -1), uv0=vec2(0, 1), normal=vec3(-1,  0,  0)), 
]

var cubeIndices = [
    0.uint32,  1,  2,      0,  2,  3,    # front
    4,  5,  6,      4,  6,  7,    # back
    8,  9,  10,     8,  10, 11,   # top
    12, 13, 14,     12, 14, 15,   # bottom
    16, 17, 18,     16, 18, 19,   # right
    20, 21, 22,     20, 22, 23,   # left
]

var meshInstance: Mesh

proc newCubeMesh*(): MeshComponent =
    new(result)
    if meshInstance == nil:
       meshInstance = newMesh(cubeVertices, cubeIndices)
    result.instance  = meshInstance
