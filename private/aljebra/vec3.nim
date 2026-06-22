import hashes
import math

import common
import vec2

# Vec3
func vec3*[T: int32|uint32|int64|uint64|float32|float64](x: T, y: T, z: T): Vec3 = Vec3(x: x.float32, y: y.float32, z: z.float32)
func ivec3*[T: int32|uint32|int64|uint64|float32|float64](x: T, y: T, z: T): IVec3 = IVec3(x: x.int32, y: y.int32, z: z.int32)
func uvec3*[T: int32|uint32|int64|uint64|float32|float64](x: T, y: T, z: T): UVec3 = UVec3(x: x.uint32, y: y.uint32, z: z.uint32)
func vec3*[T: int32|uint32|float32](a: GVec3[T]): Vec3 = Vec3(x: a.x.float32, y: a.y.float32, z: a.z.float32)
func ivec3*[T: int32|uint32|float32](a: GVec3[T]): IVec3 = IVec3(x: a.x.int32, y: a.y.int32, z: a.z.int32)
func uvec3*[T: int32|uint32|float32](a: GVec3[T]): UVec3 = UVec3(x: a.x.uint32, y: a.y.uint32, z: a.z.uint32)
func vec3*[T: int32|uint32|int64|uint64|float32|float64](x: T): Vec3 = vec3(x.float32, x.float32, x.float32)
func ivec3*[T: int32|uint32|int64|uint64|float32|float64](x: T): IVec3 = ivec3(x.int32, x.int32, x.int32)
func uvec3*[T: int32|uint32|int64|uint64|float32|float64](x: T): UVec3 = uvec3(x.uint32, x.uint32, x.uint32)
func vec3*[T: int32|uint32|int64|uint64|float32|float64](v: array[3, T]): Vec3 = Vec3(x: v[0].float32, y: v[1].float32, z: v[2].float32)
func vec3*[T: int32|uint32|int64|uint64|float32|float64](v: openArray[T], offset: int): Vec3 = Vec3(x: v[offset].float32, y: v[offset + 1].float32, z: v[offset + 2].float32)
func ivec3*[T: int32|uint32|int64|uint64|float32|float64](v: array[3, T]): IVec3 = IVec3(x: v[0].int32, y: v[1].int32, z: v[2].int32)
func ivec3*[T: int32|uint32|int64|uint64|float32|float64](v: openArray[T], offset: int): IVec3 = IVec3(x: v[offset].int32, y: v[offset + 1].int32, z: v[offset + 2].int32)
func uvec3*[T: int32|uint32|int64|uint64|float32|float64](v: array[3, T]): UVec3 = UVec3(x: v[0].uint32, y: v[1].uint32, z: v[2].uint32)
func uvec3*[T: int32|uint32|int64|uint64|float32|float64](v: openArray[T], offset: int): UVec3 = UVec3(x: v[offset].uint32, y: v[offset + 1].uint32, z: v[offset + 2].uint32)
func `+`*[T: Vec3|IVec3|UVec3](a, b: T): T = T(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z)
func `+`*[T: Vec3, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x + f.float32, y: a.y + f.float32, z: a.z + f.float32)
func `+`*[T: IVec3, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x + f.int32, y: a.y + f.int32, z: a.z + f.int32)
func `+`*[T: UVec3, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x + f.uint32, y: a.y + f.uint32, z: a.z + f.uint32)
func `+`*[T: Vec3, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: a.x + f.float32, y: a.y + f.float32, z: a.z + f.float32)
func `+`*[T: IVec3, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: a.x + f.int32, y: a.y + f.int32, z: a.z + f.int32)
func `+`*[T: UVec3, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: a.x + f.uint32, y: a.y + f.uint32, z: a.z + f.uint32)
func `-`*[T: Vec3|IVec3|UVec3](a, b: T): T = T(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z)
func `-`*[T: Vec3, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x - f.float32, y: a.y - f.float32, z: a.z - f.float32)
func `-`*[T: IVec3, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x - f.int32, y: a.y - f.int32, z: a.z - f.int32)
func `-`*[T: UVec3, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x - f.uint32, y: a.y - f.uint32, z: a.z - f.uint32)
func `-`*[T: Vec3, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: f.float32 - a.x, y: f.float32 - a.y, z: f.float32 - a.z)
func `-`*[T: IVec3, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: f.int32 - a.x, y: f.int32 - a.y, z: f.int32 - a.z)
func `-`*[T: UVec3, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: f.uint32 - a.x, y: f.uint32 - a.y, z: f.uint32 - a.z)
func `*`*[T: Vec3|IVec3|UVec3](a, b: T): T = T(x: a.x * b.x, y: a.y * b.y, z: a.z * b.z)
func `*`*[T: Vec3, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x * f.float32, y: a.y * f.float32, z: a.z * f.float32)
func `*`*[T: IVec3, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x * f.int32, y: a.y * f.int32, z: a.z * f.int32)
func `*`*[T: UVec3, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x * f.uint32, y: a.y * f.uint32, z: a.z * f.uint32)
func `*`*[T: Vec3, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: a.x * f.float32, y: a.y * f.float32, z: a.z * f.float32)
func `*`*[T: IVec3, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: a.x * f.int32, y: a.y * f.int32, z: a.z * f.int32)
func `*`*[T: UVec3, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: a.x * f.uint32, y: a.y * f.uint32, z: a.z * f.uint32)
func `/`*[T: Vec3|IVec3|UVec3](a, b: T): T = T(x: a.x / b.x, y: a.y / b.y, z: a.z / b.z)
func `/`*[T: Vec3, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x / f.float32, y: a.y / f.float32, z: a.z / f.float32)
func `/`*[T: IVec3, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x / f.int32, y: a.y / f.int32, z: a.z / f.int32)
func `/`*[T: UVec3, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x / f.uint32, y: a.y / f.uint32, z: a.z / f.uint32)
func `/`*[T: Vec3, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: f.float32 / a.x, y: f.float32 / a.y, z: f.float32 / a.z)
func `/`*[T: IVec3, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: f.int32 / a.x, y: f.int32 / a.y, z: f.int32 / a.z)
func `/`*[T: UVec3, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: f.uint32 / a.x, y: f.uint32 / a.y, z: f.uint32 / a.z)
func `+=`*[T: Vec3|IVec3|UVec3](a: var T, b: T) =
  a.x += b.x
  a.y += b.y
  a.z += b.z
func `+=`*[T: Vec3, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x += f.float32
  a.y += f.float32
  a.z += f.float32
func `+=`*[T: IVec3, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x += f.int32
  a.y += f.int32
  a.z += f.int32
func `+=`*[T: UVec3, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x += f.uint32
  a.y += f.uint32
  a.z += f.uint32
func `-=`*[T: Vec3|IVec3|UVec3](a: var T, b: T) =
  a.x -= b.x
  a.y -= b.y
  a.z -= b.z
func `-=`*[T: Vec3, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x -= f.float32
  a.y -= f.float32
  a.z -= f.float32
func `-=`*[T: IVec3, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x -= f.int32
  a.y -= f.int32
  a.z -= f.int32
func `-=`*[T: UVec3, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x -= f.uint32
  a.y -= f.uint32
  a.z -= f.uint32
func `*=`*[T: Vec3|IVec3|UVec3](a: var T, b: T) =
  a.x *= b.x
  a.y *= b.y
  a.z *= b.z
func `*=`*[T: Vec3, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x *= f.float32
  a.y *= f.float32
  a.z *= f.float32
func `*=`*[T: IVec3, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x *= f.int32
  a.y *= f.int32
  a.z *= f.int32
func `*=`*[T: UVec3, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x *= f.uint32
  a.y *= f.uint32
  a.z *= f.uint32
func `/=`*[T: Vec3|IVec3|UVec3](a: var T, b: T) =
  a.x /= b.x
  a.y /= b.y
  a.z /= b.z
func `/=`*[T: Vec3, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x /= f.float32
  a.y /= f.float32
  a.z /= f.float32
func `/=`*[T: IVec3, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x /= f.int32
  a.y /= f.int32
  a.z /= f.int32
func `/=`*[T: UVec3, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x /= f.uint32
  a.y /= f.uint32
  a.z /= f.uint32

func hash*[T](a: GVec3[T]): Hash = hash((a.x, a.y, a.z))
func dot*[T: float32|int32|uint32](a, b: GVec3[T]): T = a.x * b.x + a.y * b.y + a.z * b.z
func floor*(a: Vec3): Vec3 = Vec3(x: floor(a.x), y: floor(a.y), z: floor(a.z))
func floor*[T: int32|uint32](a: GVec3[T]): GVec3[T] = a
func round*(a: Vec3): Vec3 = Vec3(x: round(a.x), y: round(a.y), z: round(a.z))
func round*[T: int32|uint32](a: GVec3[T]): GVec3[T] = a
func ceil*(a: Vec3): Vec3 = Vec3(x: ceil(a.x), y: ceil(a.y), z: ceil(a.z))
func ceil*[T: int32|uint32](a: GVec3[T]): GVec3[T] = a
func cross*[T: float32|int32|uint32](a, b: GVec3[T]): GVec3[T] = GVec3[T](
  x: a.y * b.z - a.z * b.y,
  y: a.z * b.x - a.x * b.z,
  z: a.x * b.y - a.y * b.x
)
func lengthSq*[T: float32|int32|uint32](a: GVec3[T]): T = a.x * a.x + a.y * a.y + a.z * a.z
func length*[T: float32|int32|uint32](a: GVec3[T]): float32 = sqrt(lengthSq(a))
func clamp*[T: float32|int32|uint32](v, a, b: GVec3[T]): GVec3[T] = GVec3[T](x: clamp(v.x, a.x, b.x), y: clamp(v.y, a.y, b.y), z: clamp(v.z, a.z, b.z))
func min*[T: float32|int32|uint32](v1, v2: GVec3[T]): GVec3[T] = GVec3[T](x: min(v1.x, v2.x), y: min(v1.y, v2.y), z: min(v1.z, v2.z))
func max*[T: float32|int32|uint32](v1, v2: GVec3[T]): GVec3[T] = GVec3[T](x: max(v1.x, v2.x), y: max(v1.y, v2.y), z: max(v1.z, v2.z))
func sign*[T: float32|int32|uint32](a: GVec3[T]): GVec3[T] = GVec3[T](x: T(sgn(a.x)), y: T(sgn(a.y)), z: T(sgn(a.z)))

func normalize*(v: Vec3): Vec3 =
  let lsq = lengthSq(v)
  if lsq == 0.0:
    result = v
  else:
    let invLen = 1.0 / sqrt(lsq)
    result = Vec3(x: v.x * invLen, y: v.y * invLen, z: v.z * invLen)

func quantize*[T: float32|int32|uint32](v: GVec3[T], n: float32): GVec3[T] = GVec3[T](
  x: T(sgn(v.x).float32 * floor(abs(v.x.float32) / n) * n),
  y: T(sgn(v.y).float32 * floor(abs(v.y.float32) / n) * n),
  z: T(sgn(v.z).float32 * floor(abs(v.z.float32) / n) * n)
)

func almostEqual*[T: float32|int32|uint32](a, b: GVec3[T]): bool =
  let c = a - b
  abs(c.x).float32 < EPSILON and abs(c.y).float32 < EPSILON and abs(c.z).float32 < EPSILON

func `[]`*[T: float32|int32|uint32](a: GVec3[T], i: int): T =
  if i == 0:
    return a.x
  elif i == 1:
    return a.y
  elif i == 2:
    return a.z

func `[]=`*[T: float32|int32|uint32](a: var GVec3[T], i: int, b: T) =
  if i == 0:
    a.x = b
  elif i == 1:
    a.y = b
  elif i == 2:
    a.z = b
