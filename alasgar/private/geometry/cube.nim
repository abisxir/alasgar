import ../core
import ../utils

var vertixes: array[36, Vertex] = [
   Vertex(position: vec3(-1.0, 1.0, 1.0), 
          normal: vec3(-1.0, 0.0, 0.0), 
          uv: vec2(0.9965389966964722, 0.4871020019054413)), 
   Vertex(position: vec3(-1.0, -1.0, -1.0), 
          normal: vec3(-1.0, 0.0, 0.0), 
          uv: vec2(0.6662219762802124, 0.9973350167274475)), 
   Vertex(position: vec3(-1.0, -1.0, 1.0), 
          normal: vec3(-1.0, 0.0, 0.0), 
          uv: vec2(0.6662219762802124, 0.4871020019054413)), 
   Vertex(position: vec3(-1.0, 1.0, -1.0), 
          normal: vec3(0.0, 0.0, -1.0), 
          uv: vec2(0.6686059832572937, 0.4950549900531769)), 
   Vertex(position: vec3(1.0, -1.0, -1.0), 
          normal: vec3(0.0, 0.0, -1.0), 
          uv: vec2(0.3313939869403839, 1.000977039337158)), 
   Vertex(position: vec3(-1.0, -1.0, -1.0), 
          normal: vec3(0.0, 0.0, -1.0), 
          uv: vec2(0.3313939869403839, 0.4950549900531769)), 
   Vertex(position: vec3(1.0, 1.0, -1.0), 
          normal: vec3(1.0, 0.0, 0.0), 
          uv: vec2(-0.000391999987186864, 1.000367045402527)), 
   Vertex(position: vec3(1.0, -1.0, 1.0), 
          normal: vec3(1.0, 0.0, 0.0), 
          uv: vec2(0.331151008605957, 0.5062630176544189)), 
   Vertex(position: vec3(1.0, -1.0, -1.0), 
          normal: vec3(1.0, 0.0, 0.0), 
          uv: vec2(0.3325819969177246, 0.9998999834060669)), 
   Vertex(position: vec3(1.0, 1.0, 1.0), 
          normal: vec3(0.0, 0.0, 1.0), 
          uv: vec2(0.0002450000029057264, 0.498537003993988)), 
   Vertex(position: vec3(-1.0, -1.0, 1.0), 
          normal: vec3(0.0, 0.0, 1.0), 
          uv: vec2(0.331743985414505, 0.002558999927714467)), 
   Vertex(position: vec3(1.0, -1.0, 1.0), 
          normal: vec3(0.0, 0.0, 1.0), 
          uv: vec2(0.3304679989814758, 0.4990209937095642)), 
   Vertex(position: vec3(1.0, -1.0, -1.0), 
          normal: vec3(0.0, -1.0, 0.0), 
          uv: vec2(0.6729140281677246, -0.0008490000036545098)), 
   Vertex(position: vec3(-1.0, -1.0, 1.0), 
          normal: vec3(0.0, -1.0, 0.0), 
          uv: vec2(0.3309929966926575, 0.4930360019207001)), 
   Vertex(position: vec3(-1.0, -1.0, -1.0), 
          normal: vec3(0.0, -1.0, 0.0), 
          uv: vec2(0.3309929966926575, -0.0008490000036545098)), 
   Vertex(position: vec3(-1.0, 1.0, -1.0), 
          normal: vec3(0.0, 1.0, 0.0), 
          uv: vec2(0.6658920049667358, 0.5031939744949341)), 
   Vertex(position: vec3(1.0, 1.0, 1.0), 
          normal: vec3(0.0, 1.0, 0.0), 
          uv: vec2(0.9975829720497131, -0.0003480000013951212)), 
   Vertex(position: vec3(1.0, 1.0, -1.0), 
          normal: vec3(0.0, 1.0, 0.0), 
          uv: vec2(0.9965940117835999, 0.5028600096702576)), 
   Vertex(position: vec3(-1.0, 1.0, 1.0), 
          normal: vec3(-1.0, 0.0, 0.0), 
          uv: vec2(0.9965389966964722, 0.4871020019054413)), 
   Vertex(position: vec3(-1.0, 1.0, -1.0), 
          normal: vec3(-1.0, 0.0, 0.0), 
          uv: vec2(0.9965389966964722, 0.9973350167274475)), 
   Vertex(position: vec3(-1.0, -1.0, -1.0), 
          normal: vec3(-1.0, 0.0, 0.0), 
          uv: vec2(0.6662219762802124, 0.9973350167274475)), 
   Vertex(position: vec3(-1.0, 1.0, -1.0), 
          normal: vec3(0.0, 0.0, -1.0), 
          uv: vec2(0.6686059832572937, 0.4950549900531769)), 
   Vertex(position: vec3(1.0, 1.0, -1.0), 
          normal: vec3(0.0, 0.0, -1.0), 
          uv: vec2(0.6686059832572937, 1.000977039337158)), 
   Vertex(position: vec3(1.0, -1.0, -1.0), 
          normal: vec3(0.0, 0.0, -1.0), 
          uv: vec2(0.3313939869403839, 1.000977039337158)), 
   Vertex(position: vec3(1.0, 1.0, -1.0), 
          normal: vec3(1.0, 0.0, 0.0), 
          uv: vec2(-0.000391999987186864, 1.000367045402527)), 
   Vertex(position: vec3(1.0, 1.0, 1.0), 
          normal: vec3(1.0, 0.0, 0.0), 
          uv: vec2(0.001068999990820885, 0.5033299922943115)), 
   Vertex(position: vec3(1.0, -1.0, 1.0), 
          normal: vec3(1.0, 0.0, 0.0), 
          uv: vec2(0.331151008605957, 0.5062630176544189)), 
   Vertex(position: vec3(1.0, 1.0, 1.0), 
          normal: vec3(0.0, 0.0, 1.0), 
          uv: vec2(0.0002450000029057264, 0.498537003993988)), 
   Vertex(position: vec3(-1.0, 1.0, 1.0), 
          normal: vec3(0.0, 0.0, 1.0), 
          uv: vec2(-0.001812999951653183, 0.002812999999150634)), 
   Vertex(position: vec3(-1.0, -1.0, 1.0), 
          normal: vec3(0.0, 0.0, 1.0), 
          uv: vec2(0.331743985414505, 0.002558999927714467)), 
   Vertex(position: vec3(1.0, -1.0, -1.0), 
          normal: vec3(0.0, -1.0, 0.0), 
          uv: vec2(0.6729140281677246, -0.0008490000036545098)), 
   Vertex(position: vec3(1.0, -1.0, 1.0), 
          normal: vec3(0.0, -1.0, 0.0), 
          uv: vec2(0.6729140281677246, 0.4930360019207001)), 
   Vertex(position: vec3(-1.0, -1.0, 1.0), 
          normal: vec3(0.0, -1.0, 0.0), 
          uv: vec2(0.3309929966926575, 0.4930360019207001)), 
   Vertex(position: vec3(-1.0, 1.0, -1.0), 
          normal: vec3(0.0, 1.0, 0.0), 
          uv: vec2(0.6658920049667358, 0.5031939744949341)), 
   Vertex(position: vec3(-1.0, 1.0, 1.0), 
          normal: vec3(0.0, 1.0, 0.0), 
          uv: vec2(0.6662709712982178, 8.800000068731606e-05)), 
   Vertex(position: vec3(1.0, 1.0, 1.0), 
          normal: vec3(0.0, 1.0, 0.0), 
          uv: vec2(0.9975829720497131, -0.0003480000013951212)), 
]

var cubeVertices = [
       # Front
       Vertex(position: vec3(-1, -1,  1), uv: vec2(0, 0), normal: vec3( 0,  0,  1)),
       Vertex(position: vec3( 1, -1,  1), uv: vec2(1, 0), normal: vec3( 0,  0,  1)),
       Vertex(position: vec3( 1,  1,  1), uv: vec2(1, 1), normal: vec3( 0,  0,  1)),
       Vertex(position: vec3(-1,  1,  1), uv: vec2(0, 1), normal: vec3( 0,  0,  1)), 
       # Back
       Vertex(position: vec3(-1, -1, -1), uv: vec2(1, 0), normal: vec3( 0,  0, -1)),
       Vertex(position: vec3(-1,  1, -1), uv: vec2(1, 1), normal: vec3( 0,  0, -1)),
       Vertex(position: vec3( 1,  1, -1), uv: vec2(0, 1), normal: vec3( 0,  0, -1)),
       Vertex(position: vec3( 1, -1, -1), uv: vec2(0, 0), normal: vec3( 0,  0, -1)),
       # Top
       Vertex(position: vec3(-1,  1, -1), uv: vec2(0, 1), normal: vec3( 0,  1,  0)),
       Vertex(position: vec3(-1,  1,  1), uv: vec2(0, 0), normal: vec3( 0,  1,  0)),
       Vertex(position: vec3( 1,  1,  1), uv: vec2(1, 0), normal: vec3( 0,  1,  0)),
       Vertex(position: vec3( 1,  1, -1), uv: vec2(1, 1), normal: vec3( 0,  1,  0)),
       # Bottom
       Vertex(position: vec3(-1, -1, -1), uv: vec2(0, 0), normal: vec3( 0, -1,  0)), 
       Vertex(position: vec3( 1, -1, -1), uv: vec2(1, 0), normal: vec3( 0, -1,  0)),
       Vertex(position: vec3( 1, -1,  1), uv: vec2(1, 1), normal: vec3( 0, -1,  0)),
       Vertex(position: vec3(-1, -1,  1), uv: vec2(0, 1), normal: vec3( 0, -1,  0)),
       # Right
       Vertex(position: vec3( 1, -1, -1), uv: vec2(1, 0), normal: vec3( 1,  0,  0)),
       Vertex(position: vec3( 1,  1, -1), uv: vec2(1, 1), normal: vec3( 1,  0,  0)), 
       Vertex(position: vec3( 1,  1,  1), uv: vec2(0, 1), normal: vec3( 1,  0,  0)),
       Vertex(position: vec3( 1, -1,  1), uv: vec2(0, 0), normal: vec3( 1,  0,  0)),
       # Left
       Vertex(position: vec3(-1, -1, -1), uv: vec2(0, 0), normal: vec3(-1,  0,  0)),
       Vertex(position: vec3(-1, -1,  1), uv: vec2(1, 0), normal: vec3(-1,  0,  0)),
       Vertex(position: vec3(-1,  1,  1), uv: vec2(1, 1), normal: vec3(-1,  0,  0)),
       Vertex(position: vec3(-1,  1, -1), uv: vec2(0, 1), normal: vec3(-1,  0,  0)), 
]

var cubeIndices = [
    0.uint32,  1,  2,      0,  2,  3,    # front
    4,  5,  6,      4,  6,  7,    # back
    8,  9,  10,     8,  10, 11,   # top
    12, 13, 14,     12, 14, 15,   # bottom
    16, 17, 18,     16, 18, 19,   # right
    20, 21, 22,     20, 22, 23,   # left
]

var vertices  = [
     0.5'f32, 0.5'f32, 0.5'f32,  -0.5'f32, 0.5'f32, 0.5'f32,  -0.5'f32,-0.5'f32, 0.5'f32,  0.5'f32,-0.5'f32, 0.5'f32, # v0,v1,v2,v3 (front)
     0.5'f32, 0.5'f32, 0.5'f32,   0.5'f32,-0.5'f32, 0.5'f32,   0.5'f32,-0.5'f32,-0.5'f32,  0.5'f32, 0.5'f32,-0.5'f32, # v0,v3,v4,v5 (right)
     0.5'f32, 0.5'f32, 0.5'f32,   0.5'f32, 0.5'f32,-0.5'f32,  -0.5'f32, 0.5'f32,-0.5'f32, -0.5'f32, 0.5'f32, 0.5'f32, # v0,v5,v6,v1 (top)
    -0.5'f32, 0.5'f32, 0.5'f32,  -0.5'f32, 0.5'f32,-0.5'f32,  -0.5'f32,-0.5'f32,-0.5'f32, -0.5'f32,-0.5'f32, 0.5'f32, # v1,v6,v7,v2 (left)
    -0.5'f32,-0.5'f32,-0.5'f32,   0.5'f32,-0.5'f32,-0.5'f32,   0.5'f32,-0.5'f32, 0.5'f32, -0.5'f32,-0.5'f32, 0.5'f32, # v7,v4,v3,v2 (bottom)
     0.5'f32,-0.5'f32,-0.5'f32,  -0.5'f32,-0.5'f32,-0.5'f32,  -0.5'f32, 0.5'f32,-0.5'f32,  0.5'f32, 0.5'f32,-0.5'f32  # v4,v7,v6,v5 (back)
]


var normals = [
     0'f32, 0, 1,   0, 0, 1,   0, 0, 1,   0, 0, 1,  # v0,v1,v2,v3 (front)
     1, 0, 0,   1, 0, 0,   1, 0, 0,   1, 0, 0,  # v0,v3,v4,v5 (right)
     0, 1, 0,   0, 1, 0,   0, 1, 0,   0, 1, 0,  # v0,v5,v6,v1 (top)
    -1, 0, 0,  -1, 0, 0,  -1, 0, 0,  -1, 0, 0,  # v1,v6,v7,v2 (left)
     0,-1, 0,   0,-1, 0,   0,-1, 0,   0,-1, 0,  # v7,v4,v3,v2 (bottom)
     0, 0,-1,   0, 0,-1,   0, 0,-1,   0, 0,-1   # v4,v7,v6,v5 (back)
]

var uvs = [
    1.float32, 0,   0, 0,   0, 1,   1, 1,        #  v0,v1,v2,v3 (front)
    0, 0,   0, 1,   1, 1,   1, 0,               # v0,v3,v4,v5 (right)
    1, 1,   1, 0,   0, 0,   0, 1,               # v0,v5,v6,v1 (top)
    1, 0,   0, 0,   0, 1,   1, 1,               # v1,v6,v7,v2 (left)
    0, 1,   1, 1,   1, 0,   0, 0,               # v7,v4,v3,v2 (bottom)
    0, 1,   1, 1,   1, 0,   0, 0                # v4,v7,v6,v5 (back)
]

var indices = [
     0.uint32, 1, 2,   2, 3, 0,    # v0-v1-v2, v2-v3-v0 (front)
     4, 5, 6,   6, 7, 4,           # v0-v3-v4, v4-v5-v0 (right)
     8, 9,10,  10,11, 8,           # v0-v5-v6, v6-v1-v0 (top)
    12,13,14,  14,15,12,           # v1-v6-v7, v7-v2-v1 (left)
    16,17,18,  18,19,16,           # v7-v4-v3, v3-v2-v7 (bottom)
    20,21,22,  22,23,20            # v4-v7-v6, v6-v5-v4 (back)
]

var meshInstance: Mesh

proc newCubeMesh*(): MeshComponent =
    new(result)
    if meshInstance == nil:
       #meshInstance = newMesh(vertixes)
       #meshInstance = newMesh(vertices, normals, uvs, indices)
       meshInstance = newMesh(cubeVertices, cubeIndices)
    result.instance  = meshInstance
