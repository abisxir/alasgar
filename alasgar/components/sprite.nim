import ../core

export core 

let 
    normal = vec3(0.0, 0.0, -1.0)
var vertixes: array[6, Vertex] = [
    newVertex(
        position=vec3(1.0, 1.0, 0.0),
        normal=normal,
        uv0=vec2(1.0, 0.0)
    ),
    newVertex(
        position=vec3(-1.0, -1.0, 0.0),
        normal=normal,
        uv0=vec2(0.0, 1.0)
    ),
    newVertex(
        position=vec3(-1.0, 1.0, 0.0),
        normal=normal,
        uv0=vec2(0.0, 0.0)
    ),
    newVertex(
        position=vec3(1.0, 1.0, 0.0),
        normal=normal,
        uv0=vec2(1.0, 0.0)
    ),
    newVertex(
        position=vec3(1.0, -1.0, 0.0),
        normal=normal,
        uv0=vec2(1.0, 1.0)
    ),
    newVertex(
        position=vec3(-1.0, -1.0, 0.0),
        normal=normal,
        uv0=vec2(0.0, 1.0)
    ),
]

var spriteMesh: Mesh

proc newSpriteComponent*(): SpriteComponent =
    new(result)

    if spriteMesh == nil:
        spriteMesh = newMesh(vertixes)

    result.instance = spriteMesh

