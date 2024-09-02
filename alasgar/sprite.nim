
import mesh
import drawable
import node
import material

var vertixes: array[6, Vertex] = [
    Vertex(position: vec3(1.0, 0.0, 1.0), 
        normal: vec3(0.0, 1.0, 0.0), 
        uv: vec2(1.0, 0.0), 
        tangent: vec3(1.0, 0.0, -0.0),
        biNormal: vec3(0.0, 0.0, -1.0)), 
    Vertex(position: vec3(-1.0, 0.0, -1.0), 
        normal: vec3(0.0, 1.0, 0.0), 
        uv: vec2(0.0, 1.0), 
        tangent: vec3(1.0, 0.0, -0.0),
        biNormal: vec3(0.0, 0.0, -1.0)), 
    Vertex(position: vec3(-1.0, 0.0, 1.0), 
        normal: vec3(0.0, 1.0, 0.0), 
        uv: vec2(0.0, 0.0), 
        tangent: vec3(1.0, 0.0, -0.0),
        biNormal: vec3(0.0, 0.0, -1.0)), 
    Vertex(position: vec3(1.0, 0.0, 1.0), 
        normal: vec3(0.0, 1.0, 0.0), 
        uv: vec2(1.0, 0.0), 
        tangent: vec3(1.0, 0.0, 0.0),
        biNormal: vec3(0.0, 0.0, -1.0)), 
    Vertex(position: vec3(1.0, 0.0, -1.0), 
        normal: vec3(0.0, 1.0, 0.0), 
        uv: vec2(1.0, 1.0), 
        tangent: vec3(1.0, 0.0, 0.0),
        biNormal: vec3(0.0, 0.0, -1.0)), 
    Vertex(position: vec3(-1.0, 0.0, -1.0), 
        normal: vec3(0.0, 1.0, 0.0), 
        uv: vec2(0.0, 1.0), 
        tangent: vec3(1.0, 0.0, 0.0),
        biNormal: vec3(0.0, 0.0, -1.0)), 
]


var spriteMesh: Mesh


type
    Sprite* = ref object of Drawable


proc newSprite*(material: Material): Sprite =
    new(result)
    if spriteMesh == nil:
        spriteMesh = newMesh(vertixes)
    result.mesh = spriteMesh
    result.material = material
    result.init



