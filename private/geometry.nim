import sokol/shape
import core

type
  Geometry* = object
    vertices*: seq[shape.Vertex]
    indices*: seq[uint32]

proc cube*(g: ptr Graphics): Geometry =
  discard g
  let sizes = shape.boxSizes(1)
  var indices = newSeq[uint16](sizes.indices.num.int)

  result.vertices = newSeq[shape.Vertex](sizes.vertices.num.int)

  var buffer = shape.Buffer(
    vertices: shape.BufferItem(
      buffer: shape.Range(
        `addr`: addr result.vertices[0],
        size: sizes.vertices.size.int,
      ),
    ),
    indices: shape.BufferItem(
      buffer: shape.Range(
        `addr`: addr indices[0],
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

  result.indices = newSeq[uint32](sizes.indices.num.int)
  for i in 0 ..< sizes.indices.num.int:
    result.indices[i] = indices[i].uint32

  doAssert buffer.valid
