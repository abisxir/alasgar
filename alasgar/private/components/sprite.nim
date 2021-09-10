import ../core

export core 

var vertixes: array[6, Vertex] = [
    Vertex(position: vec3(1.0, 0.0, 1.0),
        normal: vec3(0.0, 1.0, 0.0),
        uv: vec2(1.0, 0.0)),
    Vertex(position: vec3(-1.0, 0.0, -1.0),
        normal: vec3(0.0, 1.0, 0.0),
        uv: vec2(0.0, 1.0)),
    Vertex(position: vec3(-1.0, 0.0, 1.0),
        normal: vec3(0.0, 1.0, 0.0),
        uv: vec2(0.0, 0.0)),
    Vertex(position: vec3(1.0, 0.0, 1.0),
        normal: vec3(0.0, 1.0, 0.0),
        uv: vec2(1.0, 0.0)),
    Vertex(position: vec3(1.0, 0.0, -1.0),
        normal: vec3(0.0, 1.0, 0.0),
        uv: vec2(1.0, 1.0)),
    Vertex(position: vec3(-1.0, 0.0, -1.0),
        normal: vec3(0.0, 1.0, 0.0),
        uv: vec2(0.0, 1.0)),
]

var spriteMesh: Mesh

proc newSpriteComponent*(): SpriteComponent =
    new(result)

    if spriteMesh == nil:
        spriteMesh = newMesh(vertixes)

    result.instance = spriteMesh

