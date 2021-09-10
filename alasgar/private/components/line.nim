import ../core
import ../utils

type
    LineComponent* = ref object of MeshComponent
        points*: seq[Vec3]
        empty: seq[Vertex]
        vertices: seq[Vertex]

proc updateVertices(line: LineComponent) =
    var count = len(line.points)
    if len(line.vertices) != count:
        setLen(line.vertices, count)
    if count > 0:
        for i, point in pairs(line.points):
            line.vertices[i].position = point

proc updatePoints*(line: LineComponent) =
    updateVertices(line)
    if len(line.vertices) > 0:
        update(line.instance, line.vertices)
    else:
        update(line.instance, line.empty)

proc newLineComponent*(points: openArray[Vec3], strip: bool): LineComponent =
    new(result)
    add(result.empty, Vertex(position: vec3(0)))
    add(result.points, points)
    updateVertices(result)
    result.instance = newLinesMesh(result.vertices, dynamic=true, strip=strip)
