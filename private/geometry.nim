import sokol/shape
import core

type
  Geometry* = object
    vertices*: seq[shape.Vertex]
    indices*: seq[uint16]

proc initGeometry(sizes: shape.Sizes): tuple[geometry: Geometry, buffer: shape.Buffer] =
  result.geometry.vertices = newSeq[shape.Vertex](sizes.vertices.num.int)
  result.geometry.indices = newSeq[uint16](sizes.indices.num.int)

  result.buffer = shape.Buffer(
    vertices: shape.BufferItem(
      buffer: shape.Range(
        `addr`: addr result.geometry.vertices[0],
        size: sizes.vertices.size.int,
      ),
    ),
    indices: shape.BufferItem(
      buffer: shape.Range(
        `addr`: addr result.geometry.indices[0],
        size: sizes.indices.size.int,
      ),
    ),
  )

proc cube*(g: ptr Graphics, color: Vec4): Geometry =
  discard g
  let sizes = shape.boxSizes(1)
  var (geometry, buffer) = initGeometry(sizes)

  buffer = shape.buildBox(buffer, shape.Box(
    width: 2,
    height: 2,
    depth: 2,
    tiles: 1,
    color: shape.color4f(color.x, color.y, color.z, color.w),
  ))

  doAssert buffer.valid
  result = geometry

proc cube*(g: ptr Graphics): Geometry = cube(g, vec4(1))

proc plane*(g: ptr Graphics, color: Vec4): Geometry =
  discard g
  let sizes = shape.planeSizes(1)
  var (geometry, buffer) = initGeometry(sizes)

  buffer = shape.buildPlane(buffer, shape.Plane(
    width: 2,
    depth: 2,
    tiles: 1,
    color: shape.color4f(color.x, color.y, color.z, color.w),
  ))

  doAssert buffer.valid
  result = geometry

proc plane*(g: ptr Graphics): Geometry = plane(g, vec4(1))

proc sphere*(g: ptr Graphics, color: Vec4): Geometry =
  discard g
  const
    slices = 32'u16
    stacks = 16'u16
  let sizes = shape.sphereSizes(slices, stacks)
  var (geometry, buffer) = initGeometry(sizes)

  buffer = shape.buildSphere(buffer, shape.Sphere(
    radius: 1,
    slices: slices,
    stacks: stacks,
    color: shape.color4f(color.x, color.y, color.z, color.w),
  ))

  doAssert buffer.valid
  result = geometry

proc sphere*(g: ptr Graphics): Geometry = sphere(g, vec4(1))

proc cylinder*(g: ptr Graphics, color: Vec4): Geometry =
  discard g
  const
    slices = 32'u16
    stacks = 1'u16
  let sizes = shape.cylinderSizes(slices, stacks)
  var (geometry, buffer) = initGeometry(sizes)

  buffer = shape.buildCylinder(buffer, shape.Cylinder(
    radius: 1,
    height: 2,
    slices: slices,
    stacks: stacks,
    color: shape.color4f(color.x, color.y, color.z, color.w),
  ))

  doAssert buffer.valid
  result = geometry

proc cylinder*(g: ptr Graphics): Geometry = cylinder(g, vec4(1))

proc torus*(g: ptr Graphics, color: Vec4): Geometry =
  discard g
  const
    sides = 16'u16
    rings = 32'u16
  let sizes = shape.torusSizes(sides, rings)
  var (geometry, buffer) = initGeometry(sizes)

  buffer = shape.buildTorus(buffer, shape.Torus(
    radius: 1,
    ringRadius: 0.3,
    sides: sides,
    rings: rings,
    color: shape.color4f(color.x, color.y, color.z, color.w),
  ))

  doAssert buffer.valid
  result = geometry

proc torus*(g: ptr Graphics): Geometry = torus(g, vec4(1))
