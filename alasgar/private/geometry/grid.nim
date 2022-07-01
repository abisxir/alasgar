import ../core
import ../utils

proc newGridMesh*(count: int, width: float32): MeshComponent =
    new(result)
    var data: seq[Vertex]
    var ratio = width / count.float32
    var half = width / 2'f32
    for x in 0..count:
        data.add(newVertex(vec3(-half, 0, x.float32 * ratio - half)))
        data.add(newVertex(vec3(half, 0, x.float32 * ratio - half)))
        data.add(newVertex(vec3(x.float32 * ratio - half, 0, -half)))
        data.add(newVertex(vec3(x.float32 * ratio - half, 0, half)))

    result.instance  = newLinesMesh(data)
