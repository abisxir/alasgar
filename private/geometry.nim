import sequtils

import sokol/shape
import aljebra
import core

type
  Geometry* = object
    vertices*: seq[shape.Vertex]
    indices*: seq[uint16]

func `+`*(a, b: Geometry): Geometry =
  let
    size = a.vertices.len
    bIndicesNormalized = mapIt(b.indices, it + size.uint16)
  result.vertices = concat(a.vertices, b.vertices)
  result.indices = concat(a.indices, bIndicesNormalized)

func merge*(a, b: Geometry): Geometry = a + b

func toShapeMat4(transform: common.Mat4): shape.Mat4 =
  shape.Mat4(m: [
    [transform.m00, transform.m01, transform.m02, transform.m03],
    [transform.m10, transform.m11, transform.m12, transform.m13],
    [transform.m20, transform.m21, transform.m22, transform.m23],
    [transform.m30, transform.m31, transform.m32, transform.m33],
  ])

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

proc cube*(g: ptr Graphics, box: Vec3=vec3(2), tiles: uint16=1, color: Vec4=vec4(1), transform: common.Mat4=mat4()): Geometry =
  discard g
  let sizes = shape.boxSizes(tiles.uint32)
  var (geometry, buffer) = initGeometry(sizes)

  buffer = shape.buildBox(buffer, shape.Box(
    width: box.x,
    height: box.y,
    depth: box.z,
    tiles: tiles,
    color: shape.color4f(color.x, color.y, color.z, color.w),
    transform: toShapeMat4(transform),
  ))

  doAssert buffer.valid
  result = geometry

proc plane*(g: ptr Graphics, size: Vec2, tiles: uint16, color: Vec4, transform: common.Mat4): Geometry =
  discard g
  let sizes = shape.planeSizes(tiles.uint32)
  var (geometry, buffer) = initGeometry(sizes)

  buffer = shape.buildPlane(buffer, shape.Plane(
    width: size.x,
    depth: size.y,
    tiles: tiles,
    color: shape.color4f(color.x, color.y, color.z, color.w),
    transform: toShapeMat4(transform),
  ))

  doAssert buffer.valid
  result = geometry

proc sphere*(g: ptr Graphics, radius: float32, slices, stacks: uint16, color: Vec4, transform: common.Mat4): Geometry =
  discard g
  let sizes = shape.sphereSizes(slices.uint32, stacks.uint32)
  var (geometry, buffer) = initGeometry(sizes)

  buffer = shape.buildSphere(buffer, shape.Sphere(
    radius: radius,
    slices: slices,
    stacks: stacks,
    color: shape.color4f(color.x, color.y, color.z, color.w),
    transform: toShapeMat4(transform),
  ))

  doAssert buffer.valid
  result = geometry

proc cylinder*(g: ptr Graphics, radius, height: float32, slices, stacks: uint16, color: Vec4, transform: common.Mat4): Geometry =
  discard g
  let sizes = shape.cylinderSizes(slices.uint32, stacks.uint32)
  var (geometry, buffer) = initGeometry(sizes)

  buffer = shape.buildCylinder(buffer, shape.Cylinder(
    radius: radius,
    height: height,
    slices: slices,
    stacks: stacks,
    color: shape.color4f(color.x, color.y, color.z, color.w),
    transform: toShapeMat4(transform),
  ))

  doAssert buffer.valid
  result = geometry

proc torus*(g: ptr Graphics, radius, ringRadius: float32, sides, rings: uint16, color: Vec4, transform: common.Mat4): Geometry =
  discard g
  let sizes = shape.torusSizes(sides.uint32, rings.uint32)
  var (geometry, buffer) = initGeometry(sizes)

  buffer = shape.buildTorus(buffer, shape.Torus(
    radius: radius,
    ringRadius: ringRadius,
    sides: sides,
    rings: rings,
    color: shape.color4f(color.x, color.y, color.z, color.w),
    transform: toShapeMat4(transform),
  ))

  doAssert buffer.valid
  result = geometry

proc plane*(g: ptr Graphics, color: Vec4): Geometry = plane(g, vec2(2), 1'u16, color, mat4())
proc plane*(g: ptr Graphics): Geometry = plane(g, vec4(1))
proc sphere*(g: ptr Graphics, color: Vec4): Geometry = sphere(g, 1, 32'u16, 16'u16, color, mat4())
proc sphere*(g: ptr Graphics): Geometry = sphere(g, vec4(1))
proc cylinder*(g: ptr Graphics, color: Vec4): Geometry = cylinder(g, 1, 2, 32'u16, 1'u16, color, mat4())
proc cylinder*(g: ptr Graphics): Geometry = cylinder(g, vec4(1))
proc torus*(g: ptr Graphics, color: Vec4): Geometry = torus(g, 1, 0.3, 16'u16, 32'u16, color, mat4())
proc torus*(g: ptr Graphics): Geometry = torus(g, vec4(1))
