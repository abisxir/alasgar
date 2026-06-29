import hashes
import math

import common
import vec2
import vec3

# Vec4
func vec4*[T: int32|uint32|int64|uint64|float32|float64](x: T, y: T, z: T, w: T): Vec4 = Vec4(x: x.float32, y: y.float32, z: z.float32, w: w.float32)
func ivec4*[T: int32|uint32|int64|uint64|float32|float64](x: T, y: T, z: T, w: T): IVec4 = IVec4(x: x.int32, y: y.int32, z: z.int32, w: w.int32)
func uvec4*[T: int32|uint32|int64|uint64|float32|float64](x: T, y: T, z: T, w: T): UVec4 = UVec4(x: x.uint32, y: y.uint32, z: z.uint32, w: w.uint32)
func vec4*[T: int32|uint32|float32](a: GVec4[T]): Vec4 = Vec4(x: a.x.float32, y: a.y.float32, z: a.z.float32, w: a.w.float32)
func ivec4*[T: int32|uint32|float32](a: GVec4[T]): IVec4 = IVec4(x: a.x.int32, y: a.y.int32, z: a.z.int32, w: a.w.int32)
func uvec4*[T: int32|uint32|float32](a: GVec4[T]): UVec4 = UVec4(x: a.x.uint32, y: a.y.uint32, z: a.z.uint32, w: a.w.uint32)
func vec4*[T: int32|uint32|int64|uint64|float32|float64](x: T): Vec4 = vec4(x.float32, x.float32, x.float32, x.float32)
func ivec4*[T: int32|uint32|int64|uint64|float32|float64](x: T): IVec4 = ivec4(x.int32, x.int32, x.int32, x.int32)
func uvec4*[T: int32|uint32|int64|uint64|float32|float64](x: T): UVec4 = uvec4(x.uint32, x.uint32, x.uint32, x.uint32)
func vec4*[T: int32|uint32|float32, F: int32|uint32|int64|uint64|float32|float64](a: GVec3[T], w: F): Vec4 = Vec4(x: a.x.float32, y: a.y.float32, z: a.z.float32, w: w.float32)
func ivec4*[T: int32|uint32|float32, F: int32|uint32|int64|uint64|float32|float64](a: GVec3[T], w: F): IVec4 = IVec4(x: a.x.int32, y: a.y.int32, z: a.z.int32, w: w.int32)
func uvec4*[T: int32|uint32|float32, F: int32|uint32|int64|uint64|float32|float64](a: GVec3[T], w: F): UVec4 = UVec4(x: a.x.uint32, y: a.y.uint32, z: a.z.uint32, w: w.uint32)
func vec4*[T: int32|uint32|float32, F: int32|uint32|int64|uint64|float32|float64](xy: GVec2[T], z: F, w: F): Vec4 = Vec4(x: xy.x.float32, y: xy.y.float32, z: z.float32, w: w.float32)
func ivec4*[T: int32|uint32|float32, F: int32|uint32|int64|uint64|float32|float64](xy: GVec2[T], z: F, w: F): IVec4 = IVec4(x: xy.x.int32, y: xy.y.int32, z: z.int32, w: w.int32)
func uvec4*[T: int32|uint32|float32, F: int32|uint32|int64|uint64|float32|float64](xy: GVec2[T], z: F, w: F): UVec4 = UVec4(x: xy.x.uint32, y: xy.y.uint32, z: z.uint32, w: w.uint32)
func vec4*[T: int32|uint32|int64|uint64|float32|float64](v: array[4, T]): Vec4 = Vec4(x: v[0].float32, y: v[1].float32, z: v[2].float32, w: v[3].float32)
func vec4*[T: int32|uint32|int64|uint64|float32|float64](v: openArray[T], offset: int): Vec4 = Vec4(x: v[offset].float32, y: v[offset + 1].float32, z: v[offset + 2].float32, w: v[offset + 3].float32)
func ivec4*[T: int32|uint32|int64|uint64|float32|float64](v: array[4, T]): IVec4 = IVec4(x: v[0].int32, y: v[1].int32, z: v[2].int32, w: v[3].int32)
func ivec4*[T: int32|uint32|int64|uint64|float32|float64](v: openArray[T], offset: int): IVec4 = IVec4(x: v[offset].int32, y: v[offset + 1].int32, z: v[offset + 2].int32, w: v[offset + 3].int32)
func uvec4*[T: int32|uint32|int64|uint64|float32|float64](v: array[4, T]): UVec4 = UVec4(x: v[0].uint32, y: v[1].uint32, z: v[2].uint32, w: v[3].uint32)
func uvec4*[T: int32|uint32|int64|uint64|float32|float64](v: openArray[T], offset: int): UVec4 = UVec4(x: v[offset].uint32, y: v[offset + 1].uint32, z: v[offset + 2].uint32, w: v[offset + 3].uint32)
func `+`*[T: Vec4|IVec4|UVec4](a, b: T): T = T(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z, w: a.w + b.w)
func `+`*[T: Vec4, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x + f.float32, y: a.y + f.float32, z: a.z + f.float32, w: a.w + f.float32)
func `+`*[T: IVec4, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x + f.int32, y: a.y + f.int32, z: a.z + f.int32, w: a.w + f.int32)
func `+`*[T: UVec4, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x + f.uint32, y: a.y + f.uint32, z: a.z + f.uint32, w: a.w + f.uint32)
func `+`*[T: Vec4, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: a.x + f.float32, y: a.y + f.float32, z: a.z + f.float32, w: a.w + f.float32)
func `+`*[T: IVec4, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: a.x + f.int32, y: a.y + f.int32, z: a.z + f.int32, w: a.w + f.int32)
func `+`*[T: UVec4, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: a.x + f.uint32, y: a.y + f.uint32, z: a.z + f.uint32, w: a.w + f.uint32)
func `-`*[T: Vec4|IVec4|UVec4](a, b: T): T = T(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z, w: a.w - b.w)
func `-`*[T: Vec4, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x - f.float32, y: a.y - f.float32, z: a.z - f.float32, w: a.w - f.float32)
func `-`*[T: IVec4, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x - f.int32, y: a.y - f.int32, z: a.z - f.int32, w: a.w - f.int32)
func `-`*[T: UVec4, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x - f.uint32, y: a.y - f.uint32, z: a.z - f.uint32, w: a.w - f.uint32)
func `-`*[T: Vec4, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: f.float32 - a.x, y: f.float32 - a.y, z: f.float32 - a.z, w: f.float32 - a.w)
func `-`*[T: IVec4, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: f.int32 - a.x, y: f.int32 - a.y, z: f.int32 - a.z, w: f.int32 - a.w)
func `-`*[T: UVec4, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: f.uint32 - a.x, y: f.uint32 - a.y, z: f.uint32 - a.z, w: f.uint32 - a.w)
func `*`*[T: Vec4|IVec4|UVec4](a, b: T): T = T(x: a.x * b.x, y: a.y * b.y, z: a.z * b.z, w: a.w * b.w)
func `*`*[T: Vec4, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x * f.float32, y: a.y * f.float32, z: a.z * f.float32, w: a.w * f.float32)
func `*`*[T: IVec4, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x * f.int32, y: a.y * f.int32, z: a.z * f.int32, w: a.w * f.int32)
func `*`*[T: UVec4, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x * f.uint32, y: a.y * f.uint32, z: a.z * f.uint32, w: a.w * f.uint32)
func `*`*[T: Vec4, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: a.x * f.float32, y: a.y * f.float32, z: a.z * f.float32, w: a.w * f.float32)
func `*`*[T: IVec4, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: a.x * f.int32, y: a.y * f.int32, z: a.z * f.int32, w: a.w * f.int32)
func `*`*[T: UVec4, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: a.x * f.uint32, y: a.y * f.uint32, z: a.z * f.uint32, w: a.w * f.uint32)
func `/`*[T: Vec4|IVec4|UVec4](a, b: T): T = T(x: a.x / b.x, y: a.y / b.y, z: a.z / b.z, w: a.w / b.w)
func `/`*[T: Vec4, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x / f.float32, y: a.y / f.float32, z: a.z / f.float32, w: a.w / f.float32)
func `/`*[T: IVec4, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x / f.int32, y: a.y / f.int32, z: a.z / f.int32, w: a.w / f.int32)
func `/`*[T: UVec4, F: int32|uint32|int64|uint64|float32|float64](a: T, f: F): T = T(x: a.x / f.uint32, y: a.y / f.uint32, z: a.z / f.uint32, w: a.w / f.uint32)
func `/`*[T: Vec4, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: f.float32 / a.x, y: f.float32 / a.y, z: f.float32 / a.z, w: f.float32 / a.w)
func `/`*[T: IVec4, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: f.int32 / a.x, y: f.int32 / a.y, z: f.int32 / a.z, w: f.int32 / a.w)
func `/`*[T: UVec4, F: int32|uint32|int64|uint64|float32|float64](f: F, a: T): T = T(x: f.uint32 / a.x, y: f.uint32 / a.y, z: f.uint32 / a.z, w: f.uint32 / a.w)
func `+=`*[T: Vec4|IVec4|UVec4](a: var T, b: T) =
  a.x += b.x
  a.y += b.y
  a.z += b.z
  a.w += b.w
func `+=`*[T: Vec4, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x += f.float32
  a.y += f.float32
  a.z += f.float32
  a.w += f.float32
func `+=`*[T: IVec4, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x += f.int32
  a.y += f.int32
  a.z += f.int32
  a.w += f.int32
func `+=`*[T: UVec4, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x += f.uint32
  a.y += f.uint32
  a.z += f.uint32
  a.w += f.uint32
func `-=`*[T: Vec4|IVec4|UVec4](a: var T, b: T) =
  a.x -= b.x
  a.y -= b.y
  a.z -= b.z
  a.w -= b.w
func `-=`*[T: Vec4, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x -= f.float32
  a.y -= f.float32
  a.z -= f.float32
  a.w -= f.float32
func `-=`*[T: IVec4, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x -= f.int32
  a.y -= f.int32
  a.z -= f.int32
  a.w -= f.int32
func `-=`*[T: UVec4, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x -= f.uint32
  a.y -= f.uint32
  a.z -= f.uint32
  a.w -= f.uint32
func `*=`*[T: Vec4|IVec4|UVec4](a: var T, b: T) =
  a.x *= b.x
  a.y *= b.y
  a.z *= b.z
  a.w *= b.w
func `*=`*[T: Vec4, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x *= f.float32
  a.y *= f.float32
  a.z *= f.float32
  a.w *= f.float32
func `*=`*[T: IVec4, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x *= f.int32
  a.y *= f.int32
  a.z *= f.int32
  a.w *= f.int32
func `*=`*[T: UVec4, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x *= f.uint32
  a.y *= f.uint32
  a.z *= f.uint32
  a.w *= f.uint32
func `/=`*[T: Vec4|IVec4|UVec4](a: var T, b: T) =
  a.x /= b.x
  a.y /= b.y
  a.z /= b.z
  a.w /= b.w
func `/=`*[T: Vec4, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x /= f.float32
  a.y /= f.float32
  a.z /= f.float32
  a.w /= f.float32
func `/=`*[T: IVec4, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x /= f.int32
  a.y /= f.int32
  a.z /= f.int32
  a.w /= f.int32
func `/=`*[T: UVec4, F: int32|uint32|int64|uint64|float32|float64](a: var T, f: F) =
  a.x /= f.uint32
  a.y /= f.uint32
  a.z /= f.uint32
  a.w /= f.uint32

func hash*[T](a: GVec4[T]): Hash = hash((a.x, a.y, a.z, a.w))

func dot*[T: float32|int32|uint32](a, b: GVec4[T]): T = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
func floor*(a: Vec4): Vec4 = Vec4(x: floor(a.x), y: floor(a.y), z: floor(a.z), w: floor(a.w))
func floor*[T: int32|uint32](a: GVec4[T]): GVec4[T] = a
func round*(a: Vec4): Vec4 = Vec4(x: round(a.x), y: round(a.y), z: round(a.z), w: round(a.w))
func round*[T: int32|uint32](a: GVec4[T]): GVec4[T] = a
func ceil*(a: Vec4): Vec4 = Vec4(x: ceil(a.x), y: ceil(a.y), z: ceil(a.z), w: ceil(a.w))
func ceil*[T: int32|uint32](a: GVec4[T]): GVec4[T] = a
func cross*[T: float32|int32|uint32](a, b: GVec4[T]): GVec4[T] = GVec4[T](
  x: a.y * b.z - a.z * b.y,
  y: a.z * b.x - a.x * b.z,
  z: a.x * b.y - a.y * b.x,
  w: T(0)
)
func lengthSq*[T: float32|int32|uint32](a: GVec4[T]): T = a.x * a.x + a.y * a.y + a.z * a.z + a.w * a.w
func length*[T: float32|int32|uint32](a: GVec4[T]): float32 = sqrt(lengthSq(a))
func clamp*[T: float32|int32|uint32](v, a, b: GVec4[T]): GVec4[T] = GVec4[T](x: clamp(v.x, a.x, b.x), y: clamp(v.y, a.y, b.y), z: clamp(v.z, a.z, b.z), w: clamp(v.w, a.w, b.w))
func min*[T: float32|int32|uint32](v1, v2: GVec4[T]): GVec4[T] = GVec4[T](x: min(v1.x, v2.x), y: min(v1.y, v2.y), z: min(v1.z, v2.z), w: min(v1.w, v2.w))
func max*[T: float32|int32|uint32](v1, v2: GVec4[T]): GVec4[T] = GVec4[T](x: max(v1.x, v2.x), y: max(v1.y, v2.y), z: max(v1.z, v2.z), w: max(v1.w, v2.w))
func sign*[T: float32|int32|uint32](a: GVec4[T]): GVec4[T] = GVec4[T](x: T(sgn(a.x)), y: T(sgn(a.y)), z: T(sgn(a.z)), w: T(sgn(a.w)))

func normalize*(v: Vec4): Vec4 =
    let lsq = lengthSq(v)
    if lsq == 0.0:
      result = v
    else:
      let invLen = 1.0 / sqrt(lsq)
      result = Vec4(x: v.x * invLen, y: v.y * invLen, z: v.z * invLen, w: v.w * invLen)

func quantize*[T: float32|int32|uint32](v: GVec4[T], n: float32): GVec4[T] = GVec4[T](
  x: T(sgn(v.x).float32 * floor(abs(v.x.float32) / n) * n),
  y: T(sgn(v.y).float32 * floor(abs(v.y.float32) / n) * n),
  z: T(sgn(v.z).float32 * floor(abs(v.z.float32) / n) * n),
  w: T(sgn(v.w).float32 * floor(abs(v.w.float32) / n) * n)
)

func almostEqual*[T: float32|int32|uint32](a, b: GVec4[T]): bool =
  let c = a - b
  abs(c.x).float32 < EPSILON and abs(c.y).float32 < EPSILON and abs(c.z).float32 < EPSILON and abs(c.w).float32 < EPSILON

func `[]`*[T: float32|int32|uint32](a: GVec4[T], i: int): T =
  if i == 0:
    return a.x
  elif i == 1:
    return a.y
  elif i == 2:
    return a.z
  elif i == 3:
    return a.w

func `[]=`*[T: float32|int32|uint32](a: var GVec4[T], i: int, b: T) =
  if i == 0:
    a.x = b
  elif i == 1:
    a.y = b
  elif i == 2:
    a.z = b
  elif i == 3:
    a.w = b


# Color funcs
func colorByte(value: uint8): float32 = value.float32 / 255.0

func hexValue(c: char): uint8 =
  case c
  of 'a'..'f':
    uint8(ord(c) - ord('a') + 10)
  of 'A'..'F':
    uint8(ord(c) - ord('A') + 10)
  else:
    uint8(ord(c) - ord('0'))

func hexByte(hex: string, index: int): uint8 =
  hexValue(hex[index]) shl 4 or hexValue(hex[index + 1])

func hexNibbleByte(hex: string, index: int): uint8 =
  let value = hexValue(hex[index])
  value shl 4 or value

func color*(value: (uint8, uint8, uint8)): Vec4 =
  Vec4(
    x: colorByte(value[0]),
    y: colorByte(value[1]),
    z: colorByte(value[2]),
    w: 1.0,
  )

func color*(value: (uint8, uint8, uint8, uint8)): Vec4 =
  Vec4(
    x: colorByte(value[0]),
    y: colorByte(value[1]),
    z: colorByte(value[2]),
    w: colorByte(value[3]),
  )

func color*(value: uint32): Vec4 =
  if value <= 0xFFFFFF'u32:
    result = color((
      ((value shr 16) and 0xFF).uint8,
      ((value shr 8) and 0xFF).uint8,
      (value and 0xFF).uint8,
    ))
  else:
    result = color((
      ((value shr 24) and 0xFF).uint8,
      ((value shr 16) and 0xFF).uint8,
      ((value shr 8) and 0xFF).uint8,
      (value and 0xFF).uint8,
    ))

func color*(hex: string): Vec4 =
  let start = if hex.len > 0 and hex[0] == '#': 1 else: 0
  let size = hex.len - start

  case size
  of 3:
    result = color((
      hexNibbleByte(hex, start),
      hexNibbleByte(hex, start + 1),
      hexNibbleByte(hex, start + 2),
    ))
  of 4:
    result = color((
      hexNibbleByte(hex, start),
      hexNibbleByte(hex, start + 1),
      hexNibbleByte(hex, start + 2),
      hexNibbleByte(hex, start + 3),
    ))
  of 6:
    result = color((
      hexByte(hex, start),
      hexByte(hex, start + 2),
      hexByte(hex, start + 4),
    ))
  of 8:
    result = color((
      hexByte(hex, start),
      hexByte(hex, start + 2),
      hexByte(hex, start + 4),
      hexByte(hex, start + 6),
    ))
  else:
    raise newException(ValueError, "Hex color must be RGB, RGBA, RRGGBB, or RRGGBBAA")

converter colorToVec4*(value: (uint8, uint8, uint8)): Vec4 = color(value)
converter colorToVec4*(value: (uint8, uint8, uint8, uint8)): Vec4 = color(value)
converter colorToVec4*(value: uint32): Vec4 = color(value)
converter colorToVec4*(hex: string): Vec4 = color(hex)
