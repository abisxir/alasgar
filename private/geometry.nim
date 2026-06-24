import sokol/shape
import core

type
  Geometry* = object
    vertices*: seq[shape.Vertex]
    indices*: seq[uint16]

proc cube*(g: ptr Graphics): Geometry =
  discard g
  let sizes = shape.boxSizes(1)

  result.vertices = newSeq[shape.Vertex](sizes.vertices.num.int)
  result.indices = newSeq[uint16](sizes.indices.num.int)

  var buffer = shape.Buffer(
    vertices: shape.BufferItem(
      buffer: shape.Range(
        `addr`: addr result.vertices[0],
        size: sizes.vertices.size.int,
      ),
    ),
    indices: shape.BufferItem(
      buffer: shape.Range(
        `addr`: addr result.indices[0],
        size: sizes.indices.size.int,
      ),
    ),
  )

  buffer = shape.buildBox(buffer, shape.Box(
    width: 2,
    height: 2,
    depth: 2,
    tiles: 1,
    color: shape.color4f(1, 1, 1, 1),
  ))

  doAssert buffer.valid
