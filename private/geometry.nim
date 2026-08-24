import std/math
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

proc addChamferedBoxPolygon(
  geometry: var Geometry,
  points: openArray[Vec3],
  normal: Vec3,
  color: uint32,
  transform: common.Mat4,
  vIndex: var int,
  iIndex: var uint16,
) =
  let
    first = vIndex.uint16
    origin = points[0]
    tangent = normalize(points[1] - origin)
    bitangent = normalize(cross(normal, tangent))
    transformedNormal = transform * vec4(normal, 0'f32)
    faceNormal = normalize(transformedNormal.xyz)

  var
    minU = 0'f32
    maxU = 0'f32
    minV = 0'f32
    maxV = 0'f32

  for point in points:
    let relative = point - origin
    let projectedU = dot(relative, tangent)
    let projectedV = dot(relative, bitangent)
    minU = min(minU, projectedU)
    maxU = max(maxU, projectedU)
    minV = min(minV, projectedV)
    maxV = max(maxV, projectedV)

  let
    uSize = maxU - minU
    vSize = maxV - minV

  for point in points:
    let
      transformedPoint = transform * point
      relative = point - origin
      u = (dot(relative, tangent) - minU) / uSize
      v = (dot(relative, bitangent) - minV) / vSize
    geometry.vertices[vIndex] = shape.Vertex(
      x: transformedPoint.x,
      y: transformedPoint.y,
      z: transformedPoint.z,
      normal: normal4f(faceNormal.x, faceNormal.y, faceNormal.z, 0'f32),
      u: packUnorm16(u),
      v: packUnorm16(v),
      color: color,
    )
    inc vIndex

  let winding = dot(cross(points[1] - points[0], points[2] - points[0]), normal)
  for index in 1..<(points.len - 1):
    if winding >= 0:
      geometry.indices[iIndex] = first
      inc iIndex
      geometry.indices[iIndex] = first + index.uint16
      inc iIndex
      geometry.indices[iIndex] = first + (index + 1).uint16
      inc iIndex
    else:
      geometry.indices[iIndex] = first
      inc iIndex
      geometry.indices[iIndex] = first + (index + 1).uint16
      inc iIndex
      geometry.indices[iIndex] = first + index.uint16
      inc iIndex


proc buildChamferedBox(
  geometry: var Geometry,
  box: Vec3,
  bevel: float32,
  color: uint32,
  transform: common.Mat4,
) =
  let
    dimensions = box
    half = dimensions * 0.5'f32
    bevelAmount = bevel
    x0 = -half.x
    x1 = half.x
    y0 = -half.y
    y1 = half.y
    z0 = -half.z
    z1 = half.z
    b = bevelAmount

  var
    vIndex = 0.int
    iIndex = 0.uint16

  for side in [-1'f32, 1'f32]:
    addChamferedBoxPolygon(geometry, [
      vec3(x0 + b, side * y1, z0 + b),
      vec3(x1 - b, side * y1, z0 + b),
      vec3(x1 - b, side * y1, z1 - b),
      vec3(x0 + b, side * y1, z1 - b),
    ], vec3(0'f32, side, 0'f32), color, transform, vIndex, iIndex)

    addChamferedBoxPolygon(geometry, [
      vec3(side * x1, y0 + b, z0 + b),
      vec3(side * x1, y1 - b, z0 + b),
      vec3(side * x1, y1 - b, z1 - b),
      vec3(side * x1, y0 + b, z1 - b),
    ], vec3(side, 0'f32, 0'f32), color, transform, vIndex, iIndex)

    addChamferedBoxPolygon(geometry, [
      vec3(x0 + b, y0 + b, side * z1),
      vec3(x1 - b, y0 + b, side * z1),
      vec3(x1 - b, y1 - b, side * z1),
      vec3(x0 + b, y1 - b, side * z1),
    ], vec3(0'f32, 0'f32, side), color, transform, vIndex, iIndex)

  for sy in [-1'f32, 1'f32]:
    for sz in [-1'f32, 1'f32]:
      let normal = normalize(vec3(0'f32, sy, sz))
      addChamferedBoxPolygon(geometry, [
        vec3(x0 + b, sy * (y1 - b), sz * z1),
        vec3(x1 - b, sy * (y1 - b), sz * z1),
        vec3(x1 - b, sy * y1, sz * (z1 - b)),
        vec3(x0 + b, sy * y1, sz * (z1 - b)),
      ], normal, color, transform, vIndex, iIndex)

  for sx in [-1'f32, 1'f32]:
    for sz in [-1'f32, 1'f32]:
      let normal = normalize(vec3(sx, 0, sz))
      addChamferedBoxPolygon(geometry, [
        vec3(sx * (x1 - b), y0 + b, sz * z1),
        vec3(sx * x1, y0 + b, sz * (z1 - b)),
        vec3(sx * x1, y1 - b, sz * (z1 - b)),
        vec3(sx * (x1 - b), y1 - b, sz * z1),
      ], normal, color, transform, vIndex, iIndex)

  for sx in [-1'f32, 1'f32]:
    for sy in [-1'f32, 1'f32]:
      let normal = normalize(vec3(sx, sy, 0))
      addChamferedBoxPolygon(geometry, [
        vec3(sx * x1, sy * (y1 - b), z0 + b),
        vec3(sx * (x1 - b), sy * y1, z0 + b),
        vec3(sx * (x1 - b), sy * y1, z1 - b),
        vec3(sx * x1, sy * (y1 - b), z1 - b),
      ], normal, color, transform, vIndex, iIndex)

  for sx in [-1'f32, 1'f32]:
    for sy in [-1'f32, 1'f32]:
      for sz in [-1'f32, 1'f32]:
        addChamferedBoxPolygon(geometry, [
          vec3(sx * x1, sy * (y1 - b), sz * (z1 - b)),
          vec3(sx * (x1 - b), sy * y1, sz * (z1 - b)),
          vec3(sx * (x1 - b), sy * (y1 - b), sz * z1),
        ], normalize(vec3(sx, sy, sz)), color, transform, vIndex, iIndex)

proc chamferedBox*(
  g: ptr Graphics,
  box: Vec3 = vec3(2),
  bevel: float32 = 0.1,
  color: Vec4 = vec4(1),
  transform: common.Mat4 = mat4(),
): Geometry =
  discard g
  result.vertices.setLen(6 * 4 + 12 * 4 + 8 * 3)
  result.indices.setLen(6 * 2 * 3 + 12 * 2 * 3 + 8 * 3)
  buildChamferedBox(result, box, bevel, pack.color4f(color.x, color.y, color.z, color.w), transform)

proc cube*(g: ptr Graphics, box: Vec3=vec3(2), tiles: uint16=1, color: Vec4=vec4(1), transform: common.Mat4=mat4()): Geometry =
  discard g
  let sizes = shape.boxSizes(tiles.uint32)
  var (geometry, buffer) = initGeometry(sizes)

  buffer = shape.buildBox(buffer, shape.Box(
    width: box.x,
    height: box.y,
    depth: box.z,
    tiles: tiles,
    color: pack.color4f(color.x, color.y, color.z, color.w),
    transform: toShapeMat4(transform),
  ))

  doAssert buffer.valid
  result = geometry

proc plane*(g: ptr Graphics, size: Vec2=vec2(1), tiles: uint16=1, color: Vec4=vec4(1), transform: common.Mat4=mat4()): Geometry =
  discard g
  let sizes = shape.planeSizes(tiles.uint32)
  var (geometry, buffer) = initGeometry(sizes)

  buffer = shape.buildPlane(buffer, shape.Plane(
    width: size.x,
    depth: size.y,
    tiles: tiles,
    color: pack.color4f(color.x, color.y, color.z, color.w),
    transform: toShapeMat4(transform),
  ))

  doAssert buffer.valid
  result = geometry

proc sphere*(
  g: ptr Graphics,
  radius: float32=1,
  slices: uint16=32,
  stacks: uint16=16,
  color: Vec4=vec4(1),
  transform: common.Mat4=mat4()
): Geometry =
  discard g
  let sizes = shape.sphereSizes(slices.uint32, stacks.uint32)
  var (geometry, buffer) = initGeometry(sizes)

  buffer = shape.buildSphere(buffer, shape.Sphere(
    radius: radius,
    slices: slices,
    stacks: stacks,
    color: pack.color4f(color.x, color.y, color.z, color.w),
    transform: toShapeMat4(transform),
  ))

  doAssert buffer.valid
  result = geometry

proc cylinder*(
  g: ptr Graphics,
  radius: float32=1,
  height: float32=2,
  slices: uint16=32,
  stacks: uint16=1,
  color: Vec4=vec4(1),
  transform: common.Mat4=mat4()
): Geometry =
  discard g
  let sizes = shape.cylinderSizes(slices.uint32, stacks.uint32)
  var (geometry, buffer) = initGeometry(sizes)

  buffer = shape.buildCylinder(buffer, shape.Cylinder(
    radius: radius,
    height: height,
    slices: slices,
    stacks: stacks,
    color: pack.color4f(color.x, color.y, color.z, color.w),
    transform: toShapeMat4(transform),
  ))

  doAssert buffer.valid
  result = geometry

proc torus*(
  g: ptr Graphics,
  radius: float32=1,
  ringRadius: float32=0.3,
  sides: uint16=16,
  rings: uint16=32,
  color: Vec4=vec4(1),
  transform: common.Mat4=mat4()
): Geometry =
  discard g
  let sizes = shape.torusSizes(sides.uint32, rings.uint32)
  var (geometry, buffer) = initGeometry(sizes)

  buffer = shape.buildTorus(buffer, shape.Torus(
    radius: radius,
    ringRadius: ringRadius,
    sides: sides,
    rings: rings,
    color: pack.color4f(color.x, color.y, color.z, color.w),
    transform: toShapeMat4(transform),
  ))

  doAssert buffer.valid
  result = geometry
