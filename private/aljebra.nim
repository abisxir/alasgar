import std/strformat
import std/hashes
import std/math

type
  Vec2* = object
    x*: float32
    y*: float32
  IVec2* = object
    x*: int32
    y*: int32
  UVec2* = object
    x*: uint32
    y*: uint32
  Vec3* = object
    x*: float32
    y*: float32
    z*: float32
  IVec3* = object
    x*: int32
    y*: int32
    z*: int32
  UVec3* = object
    x*: uint32
    y*: uint32
    z*: uint32
  Vec4* = object
    x*: float32
    y*: float32
    z*: float32
    w*: float32
  IVec4* = object
    x*: int32
    y*: int32
    z*: int32
    w*: int32
  UVec4* = object
    x*: uint32
    y*: uint32
    z*: uint32
    w*: uint32
  Quat* = object
    x*: float32
    y*: float32
    z*: float32
    w*: float32
  Mat3* = tuple
    m00: float32
    m01: float32
    m02: float32
    m10: float32
    m11: float32
    m12: float32
    m20: float32
    m21: float32
    m22: float32
  Mat4* = tuple
    m00: float32
    m01: float32
    m02: float32
    m03: float32
    m10: float32
    m11: float32
    m12: float32
    m13: float32
    m20: float32
    m21: float32
    m22: float32
    m23: float32
    m30: float32
    m31: float32
    m32: float32
    m33: float32

const EPSILON = 0.00001

func caddr*[T: Vec2|IVec2|UVec2|Vec3|IVec3|UVec3|Vec4|IVec4|UVec4](
  v: var T): ptr float32 = v.x.addr
func caddr*[T: Mat3|Mat4](v: var T): ptr float32 = v[0].addr
func `$`*(a: Vec2): string = &"({a.x:.4f}, {a.y:.4f})"
func `$`*(a: Vec3): string = &"({a.x:.4f}, {a.y:.4f}, {a.z:.4f})"
func `$`*(a: Vec4): string = &"({a.x:.4f}, {a.y:.4f}, {a.z:.4f}, {a.w:.4f})"
func `$`*(a: Mat3): string = &"""[{a[0]:.5f}, {a[1]:.5f}, {a[2]:.5f},
{a[3]:.5f}, {a[4]:.5f}, {a[5]:.5f},
{a[6]:.5f}, {a[7]:.5f}, {a[8]:.5f}]"""
func `$`*(a: Mat4): string = &"""[{a[0]:.5f}, {a[1]:.5f}, {a[2]:.5f}, {a[3]:.5f},
{a[4]:.5f}, {a[5]:.5f}, {a[6]:.5f}, {a[7]:.5f},
{a[8]:.5f}, {a[9]:.5f}, {a[10]:.5f}, {a[11]:.5f},
{a[12]:.5f}, {a[13]:.5f}, {a[14]:.5f}, {a[15]:.5f}]"""

# Vec2
func vec2*(x, y: float32): Vec2 = Vec2(x: x, y: y)
func ivec2*(x, y: int32): IVec2 = IVec2(x: x, y: y)
func uvec2*(x, y: uint32): UVec2 = UVec2(x: x, y: y)
func vec2*(a: Vec2): Vec2 = Vec2(x: a.x, y: a.y)
func ivec2*(a: IVec2): IVec2 = IVec2(x: a.x, y: a.y)
func uvec2*(a: UVec2): UVec2 = UVec2(x: a.x, y: a.y)
func vec2*(x: float32): Vec2 = vec2(x, x)
func ivec2*(x: int32): IVec2 = ivec2(x, x)
func uvec2*(x: uint32): UVec2 = uvec2(x, x)
func vec2*(a: IVec2): Vec2 = Vec2(x: a.x.float32, y: a.y.float32)
func vec2*(a: UVec2): Vec2 = Vec2(x: a.x.float32, y: a.y.float32)
func ivec2*(a: Vec2): IVec2 = IVec2(x: a.x.int32, y: a.y.int32)
func ivec2*(a: UVec2): IVec2 = IVec2(x: a.x.int32, y: a.y.int32)
func uvec2*(a: Vec2): UVec2 = UVec2(x: a.x.uint32, y: a.y.uint32)
func uvec2*(a: IVec2): UVec2 = UVec2(x: a.x.uint32, y: a.y.uint32)
func vec2*(v: array[2, float32]): Vec2 = vec2(v[0], v[1])
func vec2*(v: openArray[float32], offset: int): Vec2 = vec2(v[offset], v[
    offset + 1])
func `+`*[T: Vec2|IVec2|UVec2](a, b: T): T = T(x: a.x + b.x, y: a.y + b.y)
func `+`*[T: Vec2, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.float32,
    y: a.y + f.float32)
func `+`*[T: IVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.int32,
    y: a.y + f.int32)
func `+`*[T: UVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.uint32,
    y: a.y + f.uint32)
func `+`*[T: Vec2, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.float32,
    y: a.y + f.float32)
func `+`*[T: IVec2, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.int32,
    y: a.y + f.int32)
func `+`*[T: UVec2, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.uint32,
    y: a.y + f.uint32)
func `-`*[T: Vec2|IVec2|UVec2](a, b: T): T = T(x: a.x - b.x, y: a.y - b.y)
func `-`*[T: Vec2, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.float32,
    y: a.y - f.float32)
func `-`*[T: IVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.int32,
    y: a.y - f.int32)
func `-`*[T: UVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.uint32,
    y: a.y - f.uint32)
func `-`*[T: Vec2, F: float|int|uint](f: F, a: T): T = T(x: f.float32 - a.x,
    y: f.float32 - a.y)
func `-`*[T: IVec2, F: float|int|uint](f: F, a: T): T = T(x: f.int32 - a.x,
    y: f.int32 - a.y)
func `-`*[T: UVec2, F: float|int|uint](f: F, a: T): T = T(x: f.uint32 - a.x,
    y: f.uint32 - a.y)
func `*`*[T: Vec2|IVec2|UVec2](a, b: T): T = T(x: a.x * b.x, y: a.y * b.y)
func `*`*[T: Vec2, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.float32,
    y: a.y * f.float32)
func `*`*[T: IVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.int32,
    y: a.y * f.int32)
func `*`*[T: UVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.uint32,
    y: a.y * f.uint32)
func `*`*[T: Vec2, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.float32,
    y: a.y * f.float32)
func `*`*[T: IVec2, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.int32,
    y: a.y * f.int32)
func `*`*[T: UVec2, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.uint32,
    y: a.y * f.uint32)
func `/`*[T: Vec2|IVec2|UVec2](a, b: T): T = T(x: a.x / b.x, y: a.y / b.y)
func `/`*[T: Vec2, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.float32,
    y: a.y / f.float32)
func `/`*[T: IVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.int32,
    y: a.y / f.int32)
func `/`*[T: UVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.uint32,
    y: a.y / f.uint32)
func `/`*[T: Vec2, F: float|int|uint](f: F, a: T): T = T(x: f.float32 / a.x,
    y: f.float32 / a.y)
func `/`*[T: IVec2, F: float|int|uint](f: F, a: T): T = T(x: f.float32 / a.x,
    y: f.float32 / a.y)
func `/`*[T: UVec2, F: float|int|uint](f: F, a: T): T = T(x: f.float32 / a.x,
    y: f.float32 / a.y)

func `+=`*[T: Vec2|IVec2|UVec2](a: var T, b: T) =
  a.x += b.x
  a.y += b.y
func `+=`*[T: Vec2, F: float|int|uint](a: var T, f: F) =
  a.x += f.float32
  a.y += f.float32
func `+=`*[T: IVec2, F: float|int|uint](a: var T, f: F) =
  a.x += f.int32
  a.y += f.int32
func `+=`*[T: UVec2, F: float|int|uint](a: var T, f: F) =
  a.x += f.uint32
  a.y += f.uint32

func `-=`*[T: Vec2|IVec2|UVec2](a: var T, b: T) =
  a.x -= b.x
  a.y -= b.y
func `-=`*[T: Vec2, F: float|int|uint](a: var T, f: F) =
  a.x -= f.float32
  a.y -= f.float32
func `-=`*[T: IVec2, F: float|int|uint](a: var T, f: F) =
  a.x -= f.int32
  a.y -= f.int32
func `-=`*[T: UVec2, F: float|int|uint](a: var T, f: F) =
  a.x -= f.uint32
  a.y -= f.uint32

func `*=`*[T: Vec2|IVec2|UVec2](a: var T, b: T) =
  a.x *= b.x
  a.y *= b.y
func `*=`*[T: Vec2, F: float|int|uint](a: var T, f: F) =
  a.x *= f.float32
  a.y *= f.float32
func `*=`*[T: IVec2, F: float|int|uint](a: var T, f: F) =
  a.x *= f.int32
  a.y *= f.int32
func `*=`*[T: UVec2, F: float|int|uint](a: var T, f: F) =
  a.x *= f.uint32
  a.y *= f.uint32

func `/=`*[T: Vec2|IVec2|UVec2](a: var T, b: T) =
  a.x /= b.x
  a.y /= b.y
func `/=`*[T: Vec2, F: float|int|uint](a: var T, f: F) =
  a.x /= f.float32
  a.y /= f.float32
func `/=`*[T: IVec2, F: float|int|uint](a: var T, f: F) =
  a.x /= f.int32
  a.y /= f.int32
func `/=`*[T: UVec2, F: float|int|uint](a: var T, f: F) =
  a.x /= f.uint32
  a.y /= f.uint32

func hash*[T: Vec2|IVec2|UVec2](a: T): Hash = hash((a.x, a.y))

func lengthSq*(a: Vec2): float32 = a.x * a.x + a.y * a.y
func lengthSq*(a: IVec2): int32 = a.x * a.x + a.y * a.y
func lengthSq*(a: UVec2): uint32 = a.x * a.x + a.y * a.y
func dot*(a, b: Vec2): float32 = a.x * b.x + a.y * b.y
func dot*(a, b: IVec2): int32 = a.x * b.x + a.y * b.y
func dot*(a, b: UVec2): uint32 = a.x * b.x + a.y * b.y
func floor*(a: Vec2): Vec2 = vec2(floor(a.x), floor(a.y))
func floor*(a: IVec2): IVec2 = a
func floor*(a: UVec2): UVec2 = a
func round*(a: Vec2): Vec2 = vec2(round(a.x), round(a.y))
func round*(a: IVec2): IVec2 = a
func round*(a: UVec2): UVec2 = a
func ceil*(a: Vec2): Vec2 = vec2(ceil(a.x), ceil(a.y))
func ceil*(a: IVec2): IVec2 = a
func ceil*(a: UVec2): UVec2 = a
func cross*(a, b: Vec2): float32 = a.x * b.y - b.x * a.y
func clamp*(v, a, b: Vec2): Vec2 = Vec2(x: clamp(v.x, a.x, b.x), y: clamp(v.y, a.y, b.y))
func min*(v1, v2: Vec2): Vec2 = vec2(min(v1.x, v2.x), min(v1.y, v2.y))
func max*(v1, v2: Vec2): Vec2 = vec2(max(v1.x, v2.x), max(v1.y, v2.y))
func sign*(a: Vec2): Vec2 = vec2(sgn(a.x).float32, sgn(a.y).float32)

func quantize*(v: Vec2, n: float32): Vec2 =
  result.x = sgn(v.x).float32 * floor(abs(v.x) / n) * n
  result.y = sgn(v.y).float32 * floor(abs(v.y) / n) * n

func almostEquals*(a, b: Vec2): bool =
  let c = a - b
  abs(c.x) < EPSILON and abs(c.y) < EPSILON

func `[]`*(a: Vec2, i: int): float32 =
  if i == 0:
    return a.x
  elif i == 1:
    return a.y

func `[]`*(a: IVec2, i: int): int32 =
  if i == 0:
    return a.x
  elif i == 1:
    return a.y

func `[]`*(a: UVec2, i: int): uint32 =
  if i == 0:
    return a.x
  elif i == 1:
    return a.y

func `[]=`*(a: var Vec2, i: int, b: float32) =
  if i == 0:
    a.x = b
  elif i == 1:
    a.y = b

func `[]=`*(a: var IVec2, i: int, b: int32) =
  if i == 0:
    a.x = b
  elif i == 1:
    a.y = b

func `[]=`*(a: var UVec2, i: int, b: uint32) =
  if i == 0:
    a.x = b
  elif i == 1:
    a.y = b

# Vec3
func vec3*(x, y, z: float32): Vec3 = Vec3(x: x, y: y, z: z)
func ivec3*(x, y, z: int32): IVec3 = IVec3(x: x, y: y, z: z)
func uvec3*(x, y, z: uint32): UVec3 = UVec3(x: x, y: y, z: z)
func vec3*(a: Vec3): Vec3 = Vec3(x: a.x, y: a.y, z: a.z)
func ivec3*(a: IVec3): IVec3 = IVec3(x: a.x, y: a.y, z: a.z)
func uvec3*(a: UVec3): UVec3 = UVec3(x: a.x, y: a.y, z: a.z)
func vec3*(x: float32): Vec3 = vec3(x, x, x)
func ivec3*(x: int32): IVec3 = ivec3(x, x, x)
func uvec3*(x: uint32): UVec3 = uvec3(x, x, x)
func vec3*(a: IVec3): Vec3 = Vec3(x: a.x.float32, y: a.y.float32,
    z: a.z.float32)
func vec3*(a: UVec3): Vec3 = Vec3(x: a.x.float32, y: a.y.float32,
    z: a.z.float32)
func ivec3*(a: Vec3): IVec3 = IVec3(x: a.x.int32, y: a.y.int32, z: a.z.int32)
func ivec3*(a: UVec3): IVec3 = IVec3(x: a.x.int32, y: a.y.int32, z: a.z.int32)
func uvec3*(a: Vec3): UVec3 = UVec3(x: a.x.uint32, y: a.y.uint32, z: a.z.uint32)
func uvec3*(a: IVec3): UVec3 = UVec3(x: a.x.uint32, y: a.y.uint32, z: a.z.uint32)
func vec3*(v: array[3, float32]): Vec3 = vec3(v[0], v[1], v[2])
func vec3*(v: openArray[float32], offset: int): Vec3 = vec3(v[offset], v[
    offset + 1], v[offset + 2])
func `+`*[T: Vec3|IVec3|UVec3](a, b: T): T = T(x: a.x + b.x, y: a.y + b.y,
    z: a.z + b.z)
func `+`*[T: Vec3, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.float32,
    y: a.y + f.float32, z: a.z + f.float32)
func `+`*[T: IVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.int32,
    y: a.y + f.int32, z: a.z + f.int32)
func `+`*[T: UVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.uint32,
    y: a.y + f.uint32, z: a.z + f.uint32)
func `+`*[T: Vec3, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.float32,
    y: a.y + f.float32, z: a.z + f.float32)
func `+`*[T: IVec3, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.int32,
    y: a.y + f.int32, z: a.z + f.int32)
func `+`*[T: UVec3, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.uint32,
    y: a.y + f.uint32, z: a.z + f.uint32)
func `-`*[T: Vec3|IVec3|UVec3](a, b: T): T = T(x: a.x - b.x, y: a.y - b.y,
    z: a.z - b.z)
func `-`*[T: Vec3, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.float32,
    y: a.y - f.float32, z: a.z - f.float32)
func `-`*[T: IVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.int32,
    y: a.y - f.int32, z: a.z - f.int32)
func `-`*[T: UVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.uint32,
    y: a.y - f.uint32, z: a.z - f.uint32)
func `-`*[T: Vec3, F: float|int|uint](f: F, a: T): T = T(x: f.float32 - a.x,
    y: f.float32 - a.y, z: f.float32 - a.z)
func `-`*[T: IVec3, F: float|int|uint](f: F, a: T): T = T(x: f.int32 - a.x,
    y: f.int32 - a.y, z: f.int32 - a.z)
func `-`*[T: UVec3, F: float|int|uint](f: F, a: T): T = T(x: f.uint32 - a.x,
    y: f.uint32 - a.y, z: f.uint32 - a.z)
func `*`*[T: Vec3|IVec3|UVec3](a, b: T): T = T(x: a.x * b.x, y: a.y * b.y,
    z: a.z * b.z)
func `*`*[T: Vec3, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.float32,
    y: a.y * f.float32, z: a.z * f.float32)
func `*`*[T: IVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.int32,
    y: a.y * f.int32, z: a.z * f.int32)
func `*`*[T: UVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.uint32,
    y: a.y * f.uint32, z: a.z * f.uint32)
func `*`*[T: Vec3, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.float32,
    y: a.y * f.float32, z: a.z * f.float32)
func `*`*[T: IVec3, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.int32,
    y: a.y * f.int32, z: a.z * f.int32)
func `*`*[T: UVec3, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.uint32,
    y: a.y * f.uint32, z: a.z * f.uint32)
func `/`*[T: Vec3|IVec3|UVec3](a, b: T): T = T(x: a.x / b.x, y: a.y / b.y,
    z: a.z / b.z)
func `/`*[T: Vec3, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.float32,
    y: a.y / f.float32, z: a.z / f.float32)
func `/`*[T: IVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.int32,
    y: a.y / f.int32, z: a.z / f.int32)
func `/`*[T: UVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.uint32,
    y: a.y / f.uint32, z: a.z / f.uint32)
func `/`*[T: Vec3, F: float|int|uint](f: F, a: T): T = T(x: f.float32 / a.x,
    y: f.float32 / a.y, z: f.float32 / a.z)
func `/`*[T: IVec3, F: float|int|uint](f: F, a: T): T = T(x: f.int32 / a.x,
    y: f.int32 / a.y, z: f.int32 / a.z)
func `/`*[T: UVec3, F: float|int|uint](f: F, a: T): T = T(x: f.uint32 / a.x,
    y: f.uint32 / a.y, z: f.uint32 / a.z)

func `+=`*[T: Vec3|IVec3|UVec3](a: var T, b: T) =
  a.x += b.x
  a.y += b.y
  a.z += b.z
func `+=`*[T: Vec3, F: float|int|uint](a: var T, f: F) =
  a.x += f.float32
  a.y += f.float32
  a.z += f.float32
func `+=`*[T: IVec3, F: float|int|uint](a: var T, f: F) =
  a.x += f.int32
  a.y += f.int32
  a.z += f.int32
func `+=`*[T: UVec3, F: float|int|uint](a: var T, f: F) =
  a.x += f.uint32
  a.y += f.uint32
  a.z += f.uint32

func `-=`*[T: Vec3|IVec3|UVec3](a: var T, b: T) =
  a.x -= b.x
  a.y -= b.y
  a.z -= b.z
func `-=`*[T: Vec3, F: float|int|uint](a: var T, f: F) =
  a.x -= f.float32
  a.y -= f.float32
  a.z -= f.float32
func `-=`*[T: IVec3, F: float|int|uint](a: var T, f: F) =
  a.x -= f.int32
  a.y -= f.int32
  a.z -= f.int32
func `-=`*[T: UVec3, F: float|int|uint](a: var T, f: F) =
  a.x -= f.uint32
  a.y -= f.uint32
  a.z -= f.uint32

func `*=`*[T: Vec3|IVec3|UVec3](a: var T, b: T) =
  a.x *= b.x
  a.y *= b.y
  a.z *= b.z
func `*=`*[T: Vec3, F: float|int|uint](a: var T, f: F) =
  a.x *= f.float32
  a.y *= f.float32
  a.z *= f.float32
func `*=`*[T: IVec3, F: float|int|uint](a: var T, f: F) =
  a.x *= f.int32
  a.y *= f.int32
  a.z *= f.int32
func `*=`*[T: UVec3, F: float|int|uint](a: var T, f: F) =
  a.x *= f.uint32
  a.y *= f.uint32
  a.z *= f.uint32

func `/=`*[T: Vec3|IVec3|UVec3](a: var T, b: T) =
  a.x /= b.x
  a.y /= b.y
  a.z /= b.z
func `/=`*[T: Vec3, F: float|int|uint](a: var T, f: F) =
  a.x /= f.float32
  a.y /= f.float32
  a.z /= f.float32
func `/=`*[T: IVec3, F: float|int|uint](a: var T, f: F) =
  a.x /= f.int32
  a.y /= f.int32
  a.z /= f.int32
func `/=`*[T: UVec3, F: float|int|uint](a: var T, f: F) =
  a.x /= f.uint32
  a.y /= f.uint32
  a.z /= f.uint32

func hash*[T: Vec3|IVec3|UVec3](a: T): Hash = hash((a.x, a.y, a.z))

func lengthSq*(a: Vec3): float32 = a.x * a.x + a.y * a.y + a.z * a.z
func lengthSq*(a: IVec3): int32 = a.x * a.x + a.y * a.y + a.z * a.z
func lengthSq*(a: UVec3): uint32 = a.x * a.x + a.y * a.y + a.z * a.z
func dot*(a, b: Vec3): float32 = a.x * b.x + a.y * b.y + a.z * b.z
func dot*(a, b: IVec3): int32 = a.x * b.x + a.y * b.y + a.z * b.z
func dot*(a, b: UVec3): uint32 = a.x * b.x + a.y * b.y + a.z * b.z
func floor*(a: Vec3): Vec3 = vec3(floor(a.x), floor(a.y), floor(a.z))
func floor*(a: IVec3): IVec3 = a
func floor*(a: UVec3): UVec3 = a
func round*(a: Vec3): Vec3 = vec3(round(a.x), round(a.y), round(a.z))
func round*(a: IVec3): IVec3 = a
func round*(a: UVec3): UVec3 = a
func ceil*(a: Vec3): Vec3 = vec3(ceil(a.x), ceil(a.y), ceil(a.z))
func ceil*(a: IVec3): IVec3 = a
func ceil*(a: UVec3): UVec3 = a
func cross*[T: Vec3|IVec3|UVec3](a, b: T): T = vec3(a.y*b.z - a.z*b.y, a.z*b.x -
    a.x*b.z, a.x*b.y - a.y*b.x)
func clamp*(v, a, b: Vec3): Vec3 = Vec3(x: clamp(v.x, a.x, b.x), y: clamp(v.y,
    a.y, b.y), z: clamp(v.z, a.z, b.z))
func min*(v1, v2: Vec3): Vec3 = vec3(min(v1.x, v2.x), min(v1.y, v2.y), min(v1.z, v2.z))
func max*(v1, v2: Vec3): Vec3 = vec3(max(v1.x, v2.x), max(v1.y, v2.y), max(v1.z, v2.z))
func sign*(a: Vec3): Vec3 = vec3(sgn(a.x).float32, sgn(a.y).float32, sgn(a.z).float32)

func quantize*(v: Vec3, n: float32): Vec3 =
  result.x = sgn(v.x).float32 * floor(abs(v.x) / n) * n
  result.y = sgn(v.y).float32 * floor(abs(v.y) / n) * n
  result.z = sgn(v.z).float32 * floor(abs(v.z) / n) * n

func almostEquals*(a, b: Vec3): bool =
  let c = a - b
  abs(c.x) < EPSILON and abs(c.y) < EPSILON and abs(c.z) < EPSILON

func `[]`*(a: Vec3, i: int): float32 =
  if i == 0:
    return a.x
  elif i == 1:
    return a.y
  elif i == 2:
    return a.z

func `[]`*(a: IVec3, i: int): int32 =
  if i == 0:
    return a.x
  elif i == 1:
    return a.y
  elif i == 2:
    return a.z

func `[]`*(a: UVec3, i: int): uint32 =
  if i == 0:
    return a.x
  elif i == 1:
    return a.y
  elif i == 2:
    return a.z

func `[]=`*(a: var Vec3, i: int, b: float32) =
  if i == 0:
    a.x = b
  elif i == 1:
    a.y = b
  elif i == 2:
    a.z = b

func `[]=`*(a: var IVec3, i: int, b: int32) =
  if i == 0:
    a.x = b
  elif i == 1:
    a.y = b
  elif i == 2:
    a.z = b

func `[]=`*(a: var UVec3, i: int, b: uint32) =
  if i == 0:
    a.x = b
  elif i == 1:
    a.y = b
  elif i == 2:
    a.z = b

# Vec4
func vec4*(x, y, z, w: float32): Vec4 = Vec4(x: x, y: y, z: z, w: w)
func vec4*(xy: Vec2, z, w: float32): Vec4 = Vec4(x: xy.x, y: xy.y, z: z, w: w)
func ivec4*(x, y, z, w: int32): IVec4 = IVec4(x: x, y: y, z: z, w: w)
func uvec4*(x, y, z, w: uint32): UVec4 = UVec4(x: x, y: y, z: z, w: w)
func vec4*(a: Vec4): Vec4 = Vec4(x: a.x, y: a.y, z: a.z, w: a.w)
func ivec4*(a: IVec4): IVec4 = IVec4(x: a.x, y: a.y, z: a.z, w: a.w)
func uvec4*(a: UVec4): UVec4 = UVec4(x: a.x, y: a.y, z: a.z, w: a.w)
func vec4*(a: Vec3, f: float32): Vec4 = Vec4(x: a.x, y: a.y, z: a.z, w: f)
func ivec4*(a: IVec3, f: int32): IVec4 = IVec4(x: a.x, y: a.y, z: a.z, w: f)
func uvec4*(a: UVec3, f: uint32): UVec4 = UVec4(x: a.x, y: a.y, z: a.z, w: f)
func vec4*(x: float32): Vec4 = vec4(x, x, x, x)
func ivec4*(x: int32): IVec4 = ivec4(x, x, x, x)
func uvec4*(x: uint32): UVec4 = uvec4(x, x, x, x)
func vec4*(a: IVec4): Vec4 = Vec4(x: a.x.float32, y: a.y.float32,
    z: a.z.float32, w: a.w.float32)
func vec4*(a: UVec4): Vec4 = Vec4(x: a.x.float32, y: a.y.float32,
    z: a.z.float32, w: a.w.float32)
func ivec4*(a: Vec4): IVec4 = IVec4(x: a.x.int32, y: a.y.int32, z: a.z.int32, w: a.w.int32)
func ivec4*(a: UVec4): IVec4 = IVec4(x: a.x.int32, y: a.y.int32, z: a.z.int32, w: a.w.int32)
func uvec4*(a: Vec4): UVec4 = UVec4(x: a.x.uint32, y: a.y.uint32, z: a.z.uint32, w: a.w.uint32)
func uvec4*(a: IVec4): UVec4 = UVec4(x: a.x.uint32, y: a.y.uint32,
    z: a.z.uint32, w: a.w.uint32)
func vec4*(v: array[4, float32]): Vec4 = vec4(v[0], v[1], v[2], v[3])
func vec4*(v: openArray[float32], offset: int): Vec4 = vec4(v[offset], v[
    offset + 1], v[offset + 2], v[offset + 3])
func `+`*[T: Vec4|IVec4|UVec4](a, b: T): T = T(x: a.x + b.x, y: a.y + b.y,
    z: a.z + b.z, w: a.w + b.w)
func `+`*[T: Vec4, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.float32,
    y: a.y + f.float32, z: a.z + f.float32, w: a.w + f.float32)
func `+`*[T: IVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.int32,
    y: a.y + f.int32, z: a.z + f.int32, w: a.w + f.int32)
func `+`*[T: UVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.uint32,
    y: a.y + f.uint32, z: a.z + f.uint32, w: a.w + f.uint32)
func `+`*[T: Vec4, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.float32,
    y: a.y + f.float32, z: a.z + f.float32, w: a.w + f.float32)
func `+`*[T: IVec4, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.int32,
    y: a.y + f.int32, z: a.z + f.int32, w: a.w + f.int32)
func `+`*[T: UVec4, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.uint32,
    y: a.y + f.uint32, z: a.z + f.uint32, w: a.w + f.uint32)
func `-`*[T: Vec4|IVec4|UVec4](a, b: T): T = T(x: a.x - b.x, y: a.y - b.y,
    z: a.z - b.z, w: a.w - b.w)
func `-`*[T: Vec4, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.float32,
    y: a.y - f.float32, z: a.z - f.float32, w: a.w - f.float32)
func `-`*[T: IVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.int32,
    y: a.y - f.int32, z: a.z - f.int32, w: a.w - f.int32)
func `-`*[T: UVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.uint32,
    y: a.y - f.uint32, z: a.z - f.uint32, w: a.w - f.uint32)
func `-`*[T: Vec4, F: float|int|uint](f: F, a: T): T = T(x: f.float32 - a.x,
    y: f.float32 - a.y, z: f.float32 - a.z, w: f.float32 - a.w)
func `-`*[T: IVec4, F: float|int|uint](f: F, a: T): T = T(x: f.int32 - a.x,
    y: f.int32 - a.y, z: f.int32 - a.z, w: f.int32 - a.w)
func `-`*[T: UVec4, F: float|int|uint](f: F, a: T): T = T(x: f.uint32 - a.x,
    y: f.uint32 - a.y, z: f.uint32 - a.z, w: f.uint32 - a.w)
func `*`*[T: Vec4|IVec4|UVec4](a, b: T): T = T(x: a.x * b.x, y: a.y * b.y,
    z: a.z * b.z, w: a.w * b.w)
func `*`*[T: Vec4, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.float32,
    y: a.y * f.float32, z: a.z * f.float32, w: a.w * f.float32)
func `*`*[T: IVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.int32,
    y: a.y * f.int32, z: a.z * f.int32, w: a.w * f.int32)
func `*`*[T: UVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.uint32,
    y: a.y * f.uint32, z: a.z * f.uint32, w: a.w * f.uint32)
func `*`*[T: Vec4, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.float32,
    y: a.y * f.float32, z: a.z * f.float32, w: a.w * f.float32)
func `*`*[T: IVec4, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.int32,
    y: a.y * f.int32, z: a.z * f.int32, w: a.w * f.int32)
func `*`*[T: UVec4, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.uint32,
    y: a.y * f.uint32, z: a.z * f.uint32, w: a.w * f.uint32)
func `/`*[T: Vec4|IVec4|UVec4](a, b: T): T = T(x: a.x / b.x, y: a.y / b.y,
    z: a.z / b.z, w: a.w / b.w)
func `/`*[T: Vec4, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.float32,
    y: a.y / f.float32, z: a.z / f.float32, w: a.w / f.float32)
func `/`*[T: IVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.int32,
    y: a.y / f.int32, z: a.z / f.int32, w: a.w / f.int32)
func `/`*[T: UVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.uint32,
    y: a.y / f.uint32, z: a.z / f.uint32, w: a.w / f.uint32)
func `/`*[T: Vec4, F: float|int|uint](f: F, a: T): T = T(x: f.float32 / a.x,
    y: f.float32 / a.y, z: f.float32 / a.z, w: f.float32 / a.w)
func `/`*[T: IVec4, F: float|int|uint](f: F, a: T): T = T(x: f.int32 / a.x,
    y: f.int32 / a.y, z: f.int32 / a.z, w: f.int32 / a.w)
func `/`*[T: UVec4, F: float|int|uint](f: F, a: T): T = T(x: f.uint32 / a.x,
    y: f.uint32 / a.y, z: f.uint32 / a.z, w: f.uint32 / a.w)

func `+=`*[T: Vec4|IVec4|UVec4](a: var T, b: T) =
  a.x += b.x
  a.y += b.y
  a.z += b.z
  a.w += b.w
func `+=`*[T: Vec4, F: float|int|uint](a: var T, f: F) =
  a.x += f.float32
  a.y += f.float32
  a.z += f.float32
  a.w += f.float32
func `+=`*[T: IVec4, F: float|int|uint](a: var T, f: F) =
  a.x += f.int32
  a.y += f.int32
  a.z += f.int32
  a.w += f.int32
func `+=`*[T: UVec4, F: float|int|uint](a: var T, f: F) =
  a.x += f.uint32
  a.y += f.uint32
  a.z += f.uint32
  a.w += f.uint32

func `-=`*[T: Vec4|IVec4|UVec4](a: var T, b: T) =
  a.x -= b.x
  a.y -= b.y
  a.z -= b.z
  a.w -= b.w
func `-=`*[T: Vec4, F: float|int|uint](a: var T, f: F) =
  a.x -= f.float32
  a.y -= f.float32
  a.z -= f.float32
  a.w -= f.float32
func `-=`*[T: IVec4, F: float|int|uint](a: var T, f: F) =
  a.x -= f.int32
  a.y -= f.int32
  a.z -= f.int32
  a.w -= f.int32
func `-=`*[T: UVec4, F: float|int|uint](a: var T, f: F) =
  a.x -= f.uint32
  a.y -= f.uint32
  a.z -= f.uint32
  a.w -= f.uint32

func `*=`*[T: Vec4|IVec4|UVec4](a: var T, b: T) =
  a.x *= b.x
  a.y *= b.y
  a.z *= b.z
  a.w *= b.w
func `*=`*[T: Vec4, F: float|int|uint](a: var T, f: F) =
  a.x *= f.float32
  a.y *= f.float32
  a.z *= f.float32
  a.w *= f.float32
func `*=`*[T: IVec4, F: float|int|uint](a: var T, f: F) =
  a.x *= f.int32
  a.y *= f.int32
  a.z *= f.int32
  a.w *= f.int32
func `*=`*[T: UVec4, F: float|int|uint](a: var T, f: F) =
  a.x *= f.uint32
  a.y *= f.uint32
  a.z *= f.uint32
  a.w *= f.uint32

func `/=`*[T: Vec4|IVec4|UVec4](a: var T, b: T) =
  a.x /= b.x
  a.y /= b.y
  a.z /= b.z
  a.w /= b.w
func `/=`*[T: Vec4, F: float|int|uint](a: var T, f: F) =
  a.x /= f.float32
  a.y /= f.float32
  a.z /= f.float32
  a.w /= f.float32
func `/=`*[T: IVec4, F: float|int|uint](a: var T, f: F) =
  a.x /= f.int32
  a.y /= f.int32
  a.z /= f.int32
  a.w /= f.int32
func `/=`*[T: UVec4, F: float|int|uint](a: var T, f: F) =
  a.x /= f.uint32
  a.y /= f.uint32
  a.z /= f.uint32
  a.w /= f.uint32

func hash*[T: Vec4|IVec4|UVec4](a: T): Hash = hash((a.x, a.y, a.z, a.w))

func lengthSq*(a: Vec4): float32 = a.x * a.x + a.y * a.y + a.z * a.z + a.w * a.w
func lengthSq*(a: IVec4): int32 = a.x * a.x + a.y * a.y + a.z * a.z + a.w * a.w
func lengthSq*(a: UVec4): uint32 = a.x * a.x + a.y * a.y + a.z * a.z + a.w * a.w
func dot*(a, b: Vec4): float32 = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
func dot*(a, b: IVec4): int32 = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
func dot*(a, b: UVec4): uint32 = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
func floor*(a: Vec4): Vec4 = vec4(floor(a.x), floor(a.y), floor(a.z), floor(a.w))
func floor*(a: IVec4): IVec4 = a
func floor*(a: UVec4): UVec4 = a
func round*(a: Vec4): Vec4 = vec4(round(a.x), round(a.y), round(a.z), floor(a.w))
func round*(a: IVec4): IVec4 = a
func round*(a: UVec4): UVec4 = a
func ceil*(a: Vec4): Vec4 = vec4(ceil(a.x), ceil(a.y), ceil(a.z), ceil(a.w))
func ceil*(a: IVec4): IVec4 = a
func ceil*(a: UVec4): UVec4 = a
func cross*[T: Vec4|IVec4|UVec4](a, b: T): T = vec4(a.y*b.z - a.z*b.y, a.z*b.x -
    a.x*b.z, a.x*b.y - a.y*b.x, 0)
func clamp*(v, a, b: Vec4): Vec4 = Vec4(x: clamp(v.x, a.x, b.x), y: clamp(v.y,
    a.y, b.y), z: clamp(v.z, a.z, b.z), w: clamp(v.w, a.w, b.w))
func min*(v1, v2: Vec4): Vec4 = vec4(min(v1.x, v2.x), min(v1.y, v2.y), min(v1.z,
    v2.z), min(v1.w, v2.w))
func max*(v1, v2: Vec4): Vec4 = vec4(max(v1.x, v2.x), max(v1.y, v2.y), max(v1.z,
    v2.z), max(v1.w, v2.w))
func sign*(a: Vec4): Vec4 = vec4(sgn(a.x).float32, sgn(a.y).float32, sgn(
    a.z).float32, sgn(a.w).float32)

func quantize*(v: Vec4, n: float32): Vec4 =
  result.x = sgn(v.x).float32 * floor(abs(v.x) / n) * n
  result.y = sgn(v.y).float32 * floor(abs(v.y) / n) * n
  result.z = sgn(v.z).float32 * floor(abs(v.z) / n) * n
  result.w = sgn(v.w).float32 * floor(abs(v.w) / n) * n

func almostEquals*(a, b: Vec4): bool =
  let c = a - b
  abs(c.x) < EPSILON and abs(c.y) < EPSILON and abs(c.z) < EPSILON and abs(
      c.w) < EPSILON

func `[]`*(a: Vec4, i: int): float32 =
  if i == 0:
    return a.x
  elif i == 1:
    return a.y
  elif i == 2:
    return a.z
  elif i == 3:
    return a.w

func `[]`*(a: IVec4, i: int): int32 =
  if i == 0:
    return a.x
  elif i == 1:
    return a.y
  elif i == 2:
    return a.z
  elif i == 3:
    return a.w

func `[]`*(a: UVec4, i: int): uint32 =
  if i == 0:
    return a.x
  elif i == 1:
    return a.y
  elif i == 2:
    return a.z
  elif i == 3:
    return a.w

func `[]=`*(a: var Vec4, i: int, b: float32) =
  if i == 0:
    a.x = b
  elif i == 1:
    a.y = b
  elif i == 2:
    a.z = b
  elif i == 3:
    a.w = b

func `[]=`*(a: var IVec4, i: int, b: int32) =
  if i == 0:
    a.x = b
  elif i == 1:
    a.y = b
  elif i == 2:
    a.z = b
  elif i == 3:
    a.w = b

func `[]=`*(a: var UVec4, i: int, b: uint32) =
  if i == 0:
    a.x = b
  elif i == 1:
    a.y = b
  elif i == 2:
    a.z = b
  elif i == 3:
    a.w = b

# All
func `-`*[T: Vec2|IVec2|UVec2|Vec3|IVec3|UVec3|Vec4|IVec4|UVec4](a: T): T = -1 * a
func length*[T: Vec2|Vec3|Vec4](a: T): float32 = sqrt(lengthSq(a))
func distance*[T: Vec2|IVec2|UVec2|Vec3|IVec3|UVec3|Vec4|IVec4|UVec4](at,
    to: T): float32 = length(at - to).float32
func distanceSq*[T: Vec2|IVec2|UVec2|Vec3|IVec3|UVec3|Vec4|IVec4|UVec4](at,
    to: T): float32 = lengthSq(at - to).float32
func lerp*[T: float32|Vec2|Vec3|Vec4](a, b: T, v: float32): T = a * (1 - v) + b * v
func lerp*[T: int32|IVec2|IVec3|IVec4](a, b: T, v: int32): T = a * (1 - v) + b * v
func lerp*[T: uint32|UVec2|UVec3|UVec4](a, b: T, v: uint32): T = a * (1 - v) + b * v
func clamp[T: Vec2|IVec2|UVec2|Vec3|IVec3|UVec3|Vec4|IVec4|UVec4](a, b, c: T): T =
  if a < b:
    result = b
  elif a > c:
    result = c
func saturate*(v: float): float = clamp(v, EPSILON, 1.0)
func saturate*(v: Vec2): Vec2 = clamp(v, vec2(EPSILON), vec2(1.0))
func saturate*(v: Vec3): Vec3 = clamp(v, vec3(EPSILON), vec3(1.0))
func saturate*(v: Vec4): Vec4 = clamp(v, vec4(EPSILON), vec4(1.0))
func mix*[T: Vec2|Vec3|Vec4](a, b: T, v: float32): T = v * (b - a) + a
func mix*(a, b, v: float32): float32 = v * (b - a) + a

func normalize*[T: Vec2|Vec3|Vec4](a: T): T =
  let l = length(a)
  if l != 0:
    result = a / l

func dir*[T: Vec2|Vec3|Vec4](at, to: T): T = normalize(at - to)

func angle*[T: Vec2|Vec3|Vec4](a, b: T): float32 =
  let
    magA = length(a)
    magB = length(b)
  if magA != 0 and magB != 0:
    let cosTheta = dot(a, b) / (magA * magB)
    result = arccos(clamp(cosTheta, -1.0, 1.0))

## 4x4 Matrix - OpenGL row order
func mat4*(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13,
    v14, v15: float32): Mat4 =
  result[0] = v0
  result[1] = v1
  result[2] = v2
  result[3] = v3
  result[4] = v4
  result[5] = v5
  result[6] = v6
  result[7] = v7
  result[8] = v8
  result[9] = v9
  result[10] = v10
  result[11] = v11
  result[12] = v12
  result[13] = v13
  result[14] = v14
  result[15] = v15

func mat4*(a: Mat4): Mat4 = a

func mat4*(p: ptr float32): Mat4 =
  var pm = cast[ptr Mat4](p)
  result = pm[]

func mat4*(m: array[16, float32]): Mat4 =
  result[0] = m[0]
  result[1] = m[1]
  result[2] = m[2]
  result[3] = m[3]
  result[4] = m[4]
  result[5] = m[5]
  result[6] = m[6]
  result[7] = m[7]
  result[8] = m[8]
  result[9] = m[9]
  result[10] = m[10]
  result[11] = m[11]
  result[12] = m[12]
  result[13] = m[13]
  result[14] = m[14]
  result[15] = m[15]

func mat4*(): Mat4 =
  result[0] = 1
  result[1] = 0
  result[2] = 0
  result[3] = 0
  result[4] = 0
  result[5] = 1
  result[6] = 0
  result[7] = 0
  result[8] = 0
  result[9] = 0
  result[10] = 1
  result[11] = 0
  result[12] = 0
  result[13] = 0
  result[14] = 0
  result[15] = 1

func mat4*(e: float32): Mat4 =
  result[0] = e
  result[1] = e
  result[2] = e
  result[3] = e
  result[4] = e
  result[5] = e
  result[6] = e
  result[7] = e
  result[8] = e
  result[9] = e
  result[10] = e
  result[11] = e
  result[12] = e
  result[13] = e
  result[14] = e
  result[15] = e

func transpose*(a: Mat4): Mat4 =
  result[0] = a[0]
  result[1] = a[4]
  result[2] = a[8]
  result[3] = a[12]

  result[4] = a[1]
  result[5] = a[5]
  result[6] = a[9]
  result[7] = a[13]

  result[8] = a[2]
  result[9] = a[6]
  result[10] = a[10]
  result[11] = a[14]

  result[12] = a[3]
  result[13] = a[7]
  result[14] = a[11]
  result[15] = a[15]

func mat4*(v0, v1, v2, v3: Vec4): Mat4 =
  result[0] = v0.x
  result[1] = v0.y
  result[2] = v0.z
  result[3] = v0.w

  result[4] = v1.x
  result[5] = v1.y
  result[6] = v1.z
  result[7] = v1.w

  result[8] = v2.x
  result[9] = v2.y
  result[10] = v2.z
  result[11] = v2.w

  result[12] = v3.x
  result[13] = v3.y
  result[14] = v3.z
  result[15] = v3.w

func determinant*(a: Mat4): float32 =
  var
    a00 = a[0]
    a01 = a[1]
    a02 = a[2]
    a03 = a[3]
    a10 = a[4]
    a11 = a[5]
    a12 = a[6]
    a13 = a[7]
    a20 = a[8]
    a21 = a[9]
    a22 = a[10]
    a23 = a[11]
    a30 = a[12]
    a31 = a[13]
    a32 = a[14]
    a33 = a[15]

  (
      a30*a21*a12*a03 - a20*a31*a12*a03 - a30*a11*a22*a03 + a10*a31*a22*a03 +
      a20*a11*a32*a03 - a10*a21*a32*a03 - a30*a21*a02*a13 + a20*a31*a02*a13 +
      a30*a01*a22*a13 - a00*a31*a22*a13 - a20*a01*a32*a13 + a00*a21*a32*a13 +
      a30*a11*a02*a23 - a10*a31*a02*a23 - a30*a01*a12*a23 + a00*a31*a12*a23 +
      a10*a01*a32*a23 - a00*a11*a32*a23 - a20*a11*a02*a33 + a10*a21*a02*a33 +
      a20*a01*a12*a33 - a00*a21*a12*a33 - a10*a01*a22*a33 + a00*a11*a22*a33
  )

func inverse*(a: Mat4): Mat4 =
  var
    b00 = a.m00*a.m11 - a.m01*a.m10
    b01 = a.m00*a.m12 - a.m02*a.m10
    b02 = a.m00*a.m13 - a.m03*a.m10
    b03 = a.m01*a.m12 - a.m02*a.m11
    b04 = a.m01*a.m13 - a.m03*a.m11
    b05 = a.m02*a.m13 - a.m03*a.m12
    b06 = a.m20*a.m31 - a.m21*a.m30
    b07 = a.m20*a.m32 - a.m22*a.m30
    b08 = a.m20*a.m33 - a.m23*a.m30
    b09 = a.m21*a.m32 - a.m22*a.m31
    b10 = a.m21*a.m33 - a.m23*a.m31
    b11 = a.m22*a.m33 - a.m23*a.m32

  # Calculate the invese determinant
  var invDet = 1.0/(b00*b11 - b01*b10 + b02*b09 + b03*b08 - b04*b07 + b05*b06)

  result[00] = (+a.m11*b11 - a.m12*b10 + a.m13*b09)*invDet
  result[01] = (-a.m01*b11 + a.m02*b10 - a.m03*b09)*invDet
  result[02] = (+a.m31*b05 - a.m32*b04 + a.m33*b03)*invDet
  result[03] = (-a.m21*b05 + a.m22*b04 - a.m23*b03)*invDet
  result[04] = (-a.m10*b11 + a.m12*b08 - a.m13*b07)*invDet
  result[05] = (+a.m00*b11 - a.m02*b08 + a.m03*b07)*invDet
  result[06] = (-a.m30*b05 + a.m32*b02 - a.m33*b01)*invDet
  result[07] = (+a.m20*b05 - a.m22*b02 + a.m23*b01)*invDet
  result[08] = (+a.m10*b10 - a.m11*b08 + a.m13*b06)*invDet
  result[09] = (-a.m00*b10 + a.m01*b08 - a.m03*b06)*invDet
  result[10] = (+a.m30*b04 - a.m31*b02 + a.m33*b00)*invDet
  result[11] = (-a.m20*b04 + a.m21*b02 - a.m23*b00)*invDet
  result[12] = (-a.m10*b09 + a.m11*b07 - a.m12*b06)*invDet
  result[13] = (+a.m00*b09 - a.m01*b07 + a.m02*b06)*invDet
  result[14] = (-a.m30*b03 + a.m31*b01 - a.m32*b00)*invDet
  result[15] = (+a.m20*b03 - a.m21*b01 + a.m22*b00)*invDet

func `*`*(a, b: Mat4): Mat4 =
  result[00] = b.m00*a.m00 + b.m01*a.m10 + b.m02*a.m20 + b.m03*a.m30
  result[01] = b.m00*a.m01 + b.m01*a.m11 + b.m02*a.m21 + b.m03*a.m31
  result[02] = b.m00*a.m02 + b.m01*a.m12 + b.m02*a.m22 + b.m03*a.m32
  result[03] = b.m00*a.m03 + b.m01*a.m13 + b.m02*a.m23 + b.m03*a.m33
  result[04] = b.m10*a.m00 + b.m11*a.m10 + b.m12*a.m20 + b.m13*a.m30
  result[05] = b.m10*a.m01 + b.m11*a.m11 + b.m12*a.m21 + b.m13*a.m31
  result[06] = b.m10*a.m02 + b.m11*a.m12 + b.m12*a.m22 + b.m13*a.m32
  result[07] = b.m10*a.m03 + b.m11*a.m13 + b.m12*a.m23 + b.m13*a.m33
  result[08] = b.m20*a.m00 + b.m21*a.m10 + b.m22*a.m20 + b.m23*a.m30
  result[09] = b.m20*a.m01 + b.m21*a.m11 + b.m22*a.m21 + b.m23*a.m31
  result[10] = b.m20*a.m02 + b.m21*a.m12 + b.m22*a.m22 + b.m23*a.m32
  result[11] = b.m20*a.m03 + b.m21*a.m13 + b.m22*a.m23 + b.m23*a.m33
  result[12] = b.m30*a.m00 + b.m31*a.m10 + b.m32*a.m20 + b.m33*a.m30
  result[13] = b.m30*a.m01 + b.m31*a.m11 + b.m32*a.m21 + b.m33*a.m31
  result[14] = b.m30*a.m02 + b.m31*a.m12 + b.m32*a.m22 + b.m33*a.m32
  result[15] = b.m30*a.m03 + b.m31*a.m13 + b.m32*a.m23 + b.m33*a.m33


func `+`*(a, b: Mat4): Mat4 =
  result[00] = a[0] + b[0]
  result[01] = a[1] + b[1]
  result[02] = a[2] + b[2]
  result[03] = a[3] + b[3]
  result[04] = a[4] + b[4]
  result[05] = a[5] + b[5]
  result[06] = a[6] + b[6]
  result[07] = a[7] + b[7]
  result[08] = a[8] + b[8]
  result[09] = a[9] + b[9]
  result[10] = a[10] + b[10]
  result[11] = a[11] + b[11]
  result[12] = a[12] + b[12]
  result[13] = a[13] + b[13]
  result[14] = a[14] + b[14]
  result[15] = a[15] + b[15]

func `*`*(f: float32, m: Mat4): Mat4 =
  result[0] = m[0] * f
  result[1] = m[1] * f
  result[2] = m[2] * f
  result[3] = m[3] * f
  result[4] = m[4] * f
  result[5] = m[5] * f
  result[6] = m[6] * f
  result[7] = m[7] * f
  result[8] = m[8] * f
  result[9] = m[9] * f
  result[10] = m[10] * f
  result[11] = m[11] * f
  result[12] = m[12] * f
  result[13] = m[13] * f
  result[14] = m[14] * f
  result[15] = m[15] * f

func `*`*(m: Mat4, f: float32): Mat4 = f * m

func `*`*(a: Mat4, b: Vec3): Vec3 =
  result.x = a[0]*b.x + a[4]*b.y + a[8]*b.z + a[12]
  result.y = a[1]*b.x + a[5]*b.y + a[9]*b.z + a[13]
  result.z = a[2]*b.x + a[6]*b.y + a[10]*b.z + a[14]

func `*`*(a: Mat4, b: Vec4): Vec4 =
  result.x = a[0]*b.x + a[4]*b.y + a[8]*b.z + a[12]*b.w
  result.y = a[1]*b.x + a[5]*b.y + a[9]*b.z + a[13]*b.w
  result.z = a[2]*b.x + a[6]*b.y + a[10]*b.z + a[14]*b.w
  result.w = a[3]*b.x + a[7]*b.y + a[11]*b.z + a[15]*b.w

func right*(a: Mat4): Vec3 =
  result.x = a[0]
  result.y = a[1]
  result.z = a[2]

func `right=`*(a: var Mat4, b: Vec3) =
  a[0] = b.x
  a[1] = b.y
  a[2] = b.z

func up*(a: Mat4): Vec3 =
  result.x = a[4]
  result.y = a[5]
  result.z = a[6]

func `up=`*(a: var Mat4, b: Vec3) =
  a[4] = b.x
  a[5] = b.y
  a[6] = b.z

func forward*(a: Mat4): Vec3 =
  result.x = a[8]
  result.y = a[9]
  result.z = a[10]

func `forward=`*(a: var Mat4, b: Vec3) =
  a[8] = b.x
  a[9] = b.y
  a[10] = b.z

func pos*(a: Mat4): Vec3 =
  result.x = a[12]
  result.y = a[13]
  result.z = a[14]

func `pos=`*(a: var Mat4, b: Vec3) =
  a[12] = b.x
  a[13] = b.y
  a[14] = b.z

func rotationOnly*(a: Mat4): Mat4 =
  result = a
  result.pos = vec3(0, 0, 0)

func dist*(a, b: Mat4): float32 =
  var
    x = a[12] - b[12]
    y = a[13] - b[13]
    z = a[14] - b[14]
  sqrt(x*x + y*y + z*z)

func translate*(v: Vec3): Mat4 =
  result[0] = 1
  result[5] = 1
  result[10] = 1
  result[15] = 1
  result[12] = v.x
  result[13] = v.y
  result[14] = v.z

func scale*(v: Vec3): Mat4 =
  result[0] = v.x
  result[5] = v.y
  result[10] = v.z
  result[15] = 1

func close*(a: Mat4, b: Mat4): bool =
  (abs(a[0] - b[0]) > 0.001 or
    abs(a[1] - b[1]) > 0.001 or
    abs(a[2] - b[2]) > 0.001 or
    abs(a[3] - b[3]) > 0.001 or
    abs(a[4] - b[4]) > 0.001 or
    abs(a[5] - b[5]) > 0.001 or
    abs(a[6] - b[6]) > 0.001 or
    abs(a[7] - b[7]) > 0.001 or
    abs(a[8] - b[8]) > 0.001 or
    abs(a[9] - b[9]) > 0.001 or
    abs(a[10] - b[10]) > 0.001 or
    abs(a[11] - b[11]) > 0.001 or
    abs(a[12] - b[12]) > 0.001 or
    abs(a[13] - b[13]) > 0.001 or
    abs(a[14] - b[14]) > 0.001 or
    abs(a[15] - b[15]) > 0.001)

func hrp*(m: Mat4): Vec3 =
  var heading, pitch, roll: float32
  if m[1] > 0.998: # singularity at north pole
    heading = arctan2(m[2], m[10])
    pitch = PI / 2
    roll = 0
  elif m[1] < -0.998: # singularity at south pole
    heading = arctan2(m[2], m[10])
    pitch = -PI / 2
    roll = 0
  else:
    heading = arctan2(-m[8], m[0])
    pitch = arctan2(-m[6], m[5])
    roll = arcsin(m[4])
  result.x = heading
  result.y = pitch
  result.z = roll

func frustum*(left, right, bottom, top, near, far: float32): Mat4 =
  var
    rl = (right - left)
    tb = (top - bottom)
    fn = (far - near)
  result[0] = (near*2) / rl
  result[1] = 0
  result[2] = 0
  result[3] = 0
  result[4] = 0
  result[5] = (near*2) / tb
  result[6] = 0
  result[7] = 0
  result[8] = (right + left) / rl
  result[9] = (top + bottom) / tb
  result[10] = -(far + near) / fn
  result[11] = -1
  result[12] = 0
  result[13] = 0
  result[14] = -(far*near*2) / fn
  result[15] = 0

func perspective*(fovy, aspect, near, far: float32): Mat4 =
  var
    top = near * tan(fovy*PI / 360.0)
    right = top * aspect
  frustum(-right, right, -top, top, near, far)

func ortho*(left, right, bottom, top, near, far: float32): Mat4 =
  var
    rl = (right - left)
    tb = (top - bottom)
    fn = (far - near)
  result[0] = 2 / rl
  result[1] = 0
  result[2] = 0
  result[3] = 0
  result[4] = 0
  result[5] = 2 / tb
  result[6] = 0
  result[7] = 0
  result[8] = 0
  result[9] = 0
  result[10] = -2 / fn
  result[11] = 0
  result[12] = -(left + right) / rl
  result[13] = -(top + bottom) / tb
  result[14] = -(far + near) / fn
  result[15] = 1

func lookAt*(eye, center, up: Vec3): Mat4 =
  var
    eyex = eye[0]
    eyey = eye[1]
    eyez = eye[2]
    upx = up[0]
    upy = up[1]
    upz = up[2]
    centerx = center[0]
    centery = center[1]
    centerz = center[2]

  if eyex == centerx and eyey == centery and eyez == centerz:
    return mat4()

  var
    # vec3.direction(eye, center, z)
    z0 = eyex - center[0]
    z1 = eyey - center[1]
    z2 = eyez - center[2]
    # normalize (no check needed for 0 because of early return)
    len = 1/sqrt(z0*z0 + z1*z1 + z2*z2)

  z0 *= len
  z1 *= len
  z2 *= len

  var
    # vec3.normalize(vec3.cross(up, z, x))
    x0 = upy*z2 - upz*z1
    x1 = upz*z0 - upx*z2
    x2 = upx*z1 - upy*z0
  len = sqrt(x0*x0 + x1*x1 + x2*x2)
  if len == 0:
    x0 = 0
    x1 = 0
    x2 = 0
  else:
    len = 1/len
    x0 *= len
    x1 *= len
    x2 *= len

  var
    # vec3.normalize(vec3.cross(z, x, y))
    y0 = z1*x2 - z2*x1
    y1 = z2*x0 - z0*x2
    y2 = z0*x1 - z1*x0

  len = sqrt(y0*y0 + y1*y1 + y2*y2)
  if len == 0:
    y0 = 0
    y1 = 0
    y2 = 0
  else:
    len = 1/len
    y0 *= len
    y1 *= len
    y2 *= len

  result[0] = x0
  result[1] = y0
  result[2] = z0
  result[3] = 0
  result[4] = x1
  result[5] = y1
  result[6] = z1
  result[7] = 0
  result[8] = x2
  result[9] = y2
  result[10] = z2
  result[11] = 0
  result[12] = -(x0*eyex + x1*eyey + x2*eyez)
  result[13] = -(y0*eyex + y1*eyey + y2*eyez)
  result[14] = -(z0*eyex + z1*eyey + z2*eyez)
  result[15] = 1

func psgn[T](x: T): T =
  if sgn(x) < 0:
    result = -1
  else:
    result = 1

func scale*(b: Mat4): Vec3 =
  let
    b00 = b[0]
    b01 = b[1]
    b02 = b[2]
    b03 = b[3]
    b10 = b[4]
    b11 = b[5]
    b12 = b[6]
    b13 = b[7]
    b20 = b[8]
    b21 = b[9]
    b22 = b[10]
    b23 = b[11]
    xs: float32 = psgn(b00 * b01 * b02 * b03)
    ys: float32 = psgn(b10 * b11 * b12 * b13)
    zs: float32 = psgn(b20 * b21 * b22 * b23)

  result.x = xs * sqrt(b00 * b00 + b01 * b01 + b02 * b02)
  result.y = ys * sqrt(b10 * b10 + b11 * b11 + b12 * b12)
  result.z = zs * sqrt(b20 * b20 + b21 * b21 + b22 * b22)

func mat3*(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9: float32): Mat3 =
  result[0] = v0
  result[1] = v1
  result[2] = v2
  result[3] = v3
  result[4] = v4
  result[5] = v5
  result[6] = v6
  result[7] = v7
  result[8] = v8

func mat3*(v1, v2, v3: Vec3): Mat3 =
  result[0] = v1.x
  result[1] = v1.y
  result[2] = v1.z
  result[3] = v2.x
  result[4] = v2.y
  result[5] = v2.z
  result[6] = v3.x
  result[7] = v3.y
  result[8] = v3.z

func mat3*(v: float32): Mat3 =
  result[0] = v
  result[1] = v
  result[2] = v
  result[3] = v
  result[4] = v
  result[5] = v
  result[6] = v
  result[7] = v
  result[8] = v

func mat3*(): Mat3 =
  result[0] = 1
  result[1] = 0
  result[2] = 0
  result[3] = 0
  result[4] = 1
  result[5] = 0
  result[6] = 0
  result[7] = 0
  result[8] = 1

func `*`*(f: float32, m: Mat3): Mat3 =
  result[0] = m[0] * f
  result[1] = m[1] * f
  result[2] = m[2] * f
  result[3] = m[3] * f
  result[4] = m[4] * f
  result[5] = m[5] * f
  result[6] = m[6] * f
  result[7] = m[7] * f
  result[8] = m[8] * f

func `*`*(m: Mat3, f: float32): Mat3 = f * m

func `*`*(m: Mat3, v: Vec3): Vec3 =
  result.x = m.m00 * v.x + m.m01 * v.y + m.m02 * v.z
  result.y = m.m10 * v.x + m.m11 * v.y + m.m12 * v.z
  result.z = m.m20 * v.x + m.m21 * v.y + m.m22 * v.z

func caddr*(m: var Mat4): ptr float32 = m[0].addr
