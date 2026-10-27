import hashes
import math

import common

# Vec2
func vec2*[X: SomeNumber, Y: SomeNumber](x: X, y: Y): Vec2 = Vec2(x: x.float32, y: y.float32)
func ivec2*[X: SomeNumber, Y: SomeNumber](x: X, y: Y): IVec2 = IVec2(x: x.int32, y: y.int32)
func uvec2*[X: SomeNumber, Y: SomeNumber](x: X, y: Y): UVec2 = UVec2(x: x.uint32, y: y.uint32)
func vec2*[T: SomeNumber](a: GVec2[T]): Vec2 = Vec2(x: a.x.float32, y: a.y.float32)
func ivec2*[T: SomeNumber](a: GVec2[T]): IVec2 = IVec2(x: a.x.int32, y: a.y.int32)
func uvec2*[T: SomeNumber](a: GVec2[T]): UVec2 = UVec2(x: a.x.uint32, y: a.y.uint32)
func vec2*[T: SomeNumber](x: T): Vec2 = vec2(x.float32, x.float32)
func ivec2*[T: SomeNumber](x: T): IVec2 = ivec2(x.int32, x.int32)
func uvec2*[T: SomeNumber](x: T): UVec2 = uvec2(x.uint32, x.uint32)
func vec2*[T: SomeNumber](v: array[2, T]): Vec2 = Vec2(x: v[0].float32, y: v[1].float32)
func vec2*[T: SomeNumber](v: openArray[T], offset: int): Vec2 = Vec2(x: v[offset].float32, y: v[offset + 1].float32)
func ivec2*[T: SomeNumber](v: array[2, T]): IVec2 = IVec2(x: v[0].int32, y: v[1].int32)
func ivec2*[T: SomeNumber](v: openArray[T], offset: int): IVec2 = IVec2(x: v[offset].int32, y: v[offset + 1].int32)
func uvec2*[T: SomeNumber](v: array[2, T]): UVec2 = UVec2(x: v[0].uint32, y: v[1].uint32)
func uvec2*[T: SomeNumber](v: openArray[T], offset: int): UVec2 = UVec2(x: v[offset].uint32, y: v[offset + 1].uint32)
func `+`*[T: Vec2|IVec2|UVec2](a, b: T): T = T(x: a.x + b.x, y: a.y + b.y)
func `+`*[T: Vec2, F: SomeNumber](a: T, f: F): T = T(x: a.x + f.float32, y: a.y + f.float32)
func `+`*[T: IVec2, F: SomeNumber](a: T, f: F): T = T(x: a.x + f.int32, y: a.y + f.int32)
func `+`*[T: UVec2, F: SomeNumber](a: T, f: F): T = T(x: a.x + f.uint32, y: a.y + f.uint32)
func `+`*[T: Vec2, F: SomeNumber](f: F, a: T): T = T(x: a.x + f.float32, y: a.y + f.float32)
func `+`*[T: IVec2, F: SomeNumber](f: F, a: T): T = T(x: a.x + f.int32, y: a.y + f.int32)
func `+`*[T: UVec2, F: SomeNumber](f: F, a: T): T = T(x: a.x + f.uint32, y: a.y + f.uint32)
func `-`*[T: Vec2|IVec2|UVec2](a, b: T): T = T(x: a.x - b.x, y: a.y - b.y)
func `-`*[T: Vec2, F: SomeNumber](a: T, f: F): T = T(x: a.x - f.float32, y: a.y - f.float32)
func `-`*[T: IVec2, F: SomeNumber](a: T, f: F): T = T(x: a.x - f.int32, y: a.y - f.int32)
func `-`*[T: UVec2, F: SomeNumber](a: T, f: F): T = T(x: a.x - f.uint32, y: a.y - f.uint32)
func `-`*[T: Vec2, F: SomeNumber](f: F, a: T): T = T(x: f.float32 - a.x, y: f.float32 - a.y)
func `-`*[T: IVec2, F: SomeNumber](f: F, a: T): T = T(x: f.int32 - a.x, y: f.int32 - a.y)
func `-`*[T: UVec2, F: SomeNumber](f: F, a: T): T = T(x: f.uint32 - a.x, y: f.uint32 - a.y)
func `*`*[T: Vec2|IVec2|UVec2](a, b: T): T = T(x: a.x * b.x, y: a.y * b.y)
func `*`*[T: Vec2, F: SomeNumber](a: T, f: F): T = T(x: a.x * f.float32, y: a.y * f.float32)
func `*`*[T: IVec2, F: SomeNumber](a: T, f: F): T = T(x: a.x * f.int32, y: a.y * f.int32)
func `*`*[T: UVec2, F: SomeNumber](a: T, f: F): T = T(x: a.x * f.uint32, y: a.y * f.uint32)
func `*`*[T: Vec2, F: SomeNumber](f: F, a: T): T = T(x: a.x * f.float32, y: a.y * f.float32)
func `*`*[T: IVec2, F: SomeNumber](f: F, a: T): T = T(x: a.x * f.int32, y: a.y * f.int32)
func `*`*[T: UVec2, F: SomeNumber](f: F, a: T): T = T(x: a.x * f.uint32, y: a.y * f.uint32)
func `/`*[T: Vec2|IVec2|UVec2](a, b: T): T = T(x: a.x / b.x, y: a.y / b.y)
func `/`*[T: Vec2, F: SomeNumber](a: T, f: F): T = T(x: a.x / f.float32, y: a.y / f.float32)
func `/`*[T: IVec2, F: SomeNumber](a: T, f: F): T = T(x: a.x / f.int32, y: a.y / f.int32)
func `/`*[T: UVec2, F: SomeNumber](a: T, f: F): T = T(x: a.x / f.uint32, y: a.y / f.uint32)
func `/`*[T: Vec2, F: SomeNumber](f: F, a: T): T = T(x: f.float32 / a.x, y: f.float32 / a.y)
func `/`*[T: IVec2, F: SomeNumber](f: F, a: T): T = T(x: f.int32 / a.x, y: f.int32 / a.y)
func `/`*[T: UVec2, F: SomeNumber](f: F, a: T): T = T(x: f.uint32 / a.x, y: f.uint32 / a.y)
func `+=`*[T: Vec2|IVec2|UVec2](a: var T, b: T) =
  a.x += b.x
  a.y += b.y
func `+=`*[T: Vec2, F: SomeNumber](a: var T, f: F) =
  a.x += f.float32
  a.y += f.float32
func `+=`*[T: IVec2, F: SomeNumber](a: var T, f: F) =
  a.x += f.int32
  a.y += f.int32
func `+=`*[T: UVec2, F: SomeNumber](a: var T, f: F) =
  a.x += f.uint32
  a.y += f.uint32
func `-=`*[T: Vec2|IVec2|UVec2](a: var T, b: T) =
  a.x -= b.x
  a.y -= b.y
func `-=`*[T: Vec2, F: SomeNumber](a: var T, f: F) =
  a.x -= f.float32
  a.y -= f.float32
func `-=`*[T: IVec2, F: SomeNumber](a: var T, f: F) =
  a.x -= f.int32
  a.y -= f.int32
func `-=`*[T: UVec2, F: SomeNumber](a: var T, f: F) =
  a.x -= f.uint32
  a.y -= f.uint32
func `*=`*[T: Vec2|IVec2|UVec2](a: var T, b: T) =
  a.x *= b.x
  a.y *= b.y
func `*=`*[T: Vec2, F: SomeNumber](a: var T, f: F) =
  a.x *= f.float32
  a.y *= f.float32
func `*=`*[T: IVec2, F: SomeNumber](a: var T, f: F) =
  a.x *= f.int32
  a.y *= f.int32
func `*=`*[T: UVec2, F: SomeNumber](a: var T, f: F) =
  a.x *= f.uint32
  a.y *= f.uint32
func `/=`*[T: Vec2|IVec2|UVec2](a: var T, b: T) =
  a.x /= b.x
  a.y /= b.y
func `/=`*[T: Vec2, F: SomeNumber](a: var T, f: F) =
  a.x /= f.float32
  a.y /= f.float32
func `/=`*[T: IVec2, F: SomeNumber](a: var T, f: F) =
  a.x /= f.int32
  a.y /= f.int32
func `/=`*[T: UVec2, F: SomeNumber](a: var T, f: F) =
  a.x /= f.uint32
  a.y /= f.uint32

func hash*[T](a: GVec2[T]): Hash = hash((a.x, a.y))
func dot*[T: SomeNumber](a, b: GVec2[T]): T = a.x * b.x + a.y * b.y
func floor*(a: Vec2): Vec2 = Vec2(x: floor(a.x), y: floor(a.y))
func floor*[T: SomeInteger](a: GVec2[T]): GVec2[T] = a
func round*(a: Vec2): Vec2 = Vec2(x: round(a.x), y: round(a.y))
func round*[T: SomeInteger](a: GVec2[T]): GVec2[T] = a
func ceil*(a: Vec2): Vec2 = Vec2(x: ceil(a.x), y: ceil(a.y))
func ceil*[T: SomeInteger](a: GVec2[T]): GVec2[T] = a
func lengthSq*[T: SomeNumber](a: GVec2[T]): T = a.x * a.x + a.y * a.y
func length*[T: SomeNumber](a: GVec2[T]): float32 = sqrt(lengthSq(a))
func cross*[T: SomeNumber](a, b: GVec2[T]): T = a.x * b.y - b.x * a.y
func clamp*[T: SomeNumber](v, a, b: GVec2[T]): GVec2[T] = GVec2[T](x: clamp(v.x, a.x, b.x), y: clamp(v.y, a.y, b.y))
func min*[T: SomeNumber](v1, v2: GVec2[T]): GVec2[T] = GVec2[T](x: min(v1.x, v2.x), y: min(v1.y, v2.y))
func max*[T: SomeNumber](v1, v2: GVec2[T]): GVec2[T] = GVec2[T](x: max(v1.x, v2.x), y: max(v1.y, v2.y))
func sign*[T: SomeNumber](a: GVec2[T]): GVec2[T] = GVec2[T](x: T(sgn(a.x)), y: T(sgn(a.y)))

func normalize*(v: Vec2): Vec2 =
  let lsq = lengthSq(v)
  if lsq == 0.0:
    result = v
  else:
    let invLen = 1.0 / sqrt(lsq)
    result = Vec2(x: v.x * invLen, y: v.y * invLen)

func quantize*[T: SomeNumber](v: GVec2[T], n: float32): GVec2[T] = GVec2[T](
  x: T(sgn(v.x).float32 * floor(abs(v.x.float32) / n) * n),
  y: T(sgn(v.y).float32 * floor(abs(v.y.float32) / n) * n)
)

func almostEqual*[T: SomeNumber](a, b: GVec2[T]): bool =
  let c = a - b
  abs(c.x).float32 < EPSILON and abs(c.y).float32 < EPSILON

func `[]`*[T: SomeNumber](a: GVec2[T], i: int): T =
  if i == 0:
    return a.x
  elif i == 1:
    return a.y

func `[]=`*[T: SomeNumber](a: var GVec2[T], i: int, b: T) =
  if i == 0:
    a.x = b
  elif i == 1:
    a.y = b
