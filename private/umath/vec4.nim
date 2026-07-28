import hashes
import math
import strutils

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

const webColorMap = {
  "aliceblue": color(0xf0f8ff'u32),
  "antiquewhite": color(0xfaebd7'u32),
  "aqua": color(0x00ffff'u32),
  "aquamarine": color(0x7fffd4'u32),
  "azure": color(0xf0ffff'u32),
  "beige": color(0xf5f5dc'u32),
  "bisque": color(0xffe4c4'u32),
  "black": color(0x000000'u32),
  "blanchedalmond": color(0xffebcd'u32),
  "blue": color(0x0000ff'u32),
  "blueviolet": color(0x8a2be2'u32),
  "brown": color(0xa52a2a'u32),
  "burlywood": color(0xdeb887'u32),
  "cadetblue": color(0x5f9ea0'u32),
  "chartreuse": color(0x7fff00'u32),
  "chocolate": color(0xd2691e'u32),
  "coral": color(0xff7f50'u32),
  "cornflowerblue": color(0x6495ed'u32),
  "cornsilk": color(0xfff8dc'u32),
  "crimson": color(0xdc143c'u32),
  "cyan": color(0x00ffff'u32),
  "darkblue": color(0x00008b'u32),
  "darkcyan": color(0x008b8b'u32),
  "darkgoldenrod": color(0xb8860b'u32),
  "darkgray": color(0xa9a9a9'u32),
  "darkgreen": color(0x006400'u32),
  "darkgrey": color(0xa9a9a9'u32),
  "darkkhaki": color(0xbdb76b'u32),
  "darkmagenta": color(0x8b008b'u32),
  "darkolivegreen": color(0x556b2f'u32),
  "darkorange": color(0xff8c00'u32),
  "darkorchid": color(0x9932cc'u32),
  "darkred": color(0x8b0000'u32),
  "darksalmon": color(0xe9967a'u32),
  "darkseagreen": color(0x8fbc8f'u32),
  "darkslateblue": color(0x483d8b'u32),
  "darkslategray": color(0x2f4f4f'u32),
  "darkslategrey": color(0x2f4f4f'u32),
  "darkturquoise": color(0x00ced1'u32),
  "darkviolet": color(0x9400d3'u32),
  "deeppink": color(0xff1493'u32),
  "deepskyblue": color(0x00bfff'u32),
  "dimgray": color(0x696969'u32),
  "dimgrey": color(0x696969'u32),
  "dodgerblue": color(0x1e90ff'u32),
  "firebrick": color(0xb22222'u32),
  "floralwhite": color(0xfffaf0'u32),
  "forestgreen": color(0x228b22'u32),
  "fuchsia": color(0xff00ff'u32),
  "gainsboro": color(0xdcdcdc'u32),
  "ghostwhite": color(0xf8f8ff'u32),
  "gold": color(0xffd700'u32),
  "goldenrod": color(0xdaa520'u32),
  "gray": color(0x808080'u32),
  "green": color(0x008000'u32),
  "greenyellow": color(0xadff2f'u32),
  "grey": color(0x808080'u32),
  "honeydew": color(0xf0fff0'u32),
  "hotpink": color(0xff69b4'u32),
  "indianred": color(0xcd5c5c'u32),
  "indigo": color(0x4b0082'u32),
  "ivory": color(0xfffff0'u32),
  "khaki": color(0xf0e68c'u32),
  "lavender": color(0xe6e6fa'u32),
  "lavenderblush": color(0xfff0f5'u32),
  "lawngreen": color(0x7cfc00'u32),
  "lemonchiffon": color(0xfffacd'u32),
  "lightblue": color(0xadd8e6'u32),
  "lightcoral": color(0xf08080'u32),
  "lightcyan": color(0xe0ffff'u32),
  "lightgoldenrodyellow": color(0xfafad2'u32),
  "lightgray": color(0xd3d3d3'u32),
  "lightgreen": color(0x90ee90'u32),
  "lightgrey": color(0xd3d3d3'u32),
  "lightpink": color(0xffb6c1'u32),
  "lightsalmon": color(0xffa07a'u32),
  "lightseagreen": color(0x20b2aa'u32),
  "lightskyblue": color(0x87cefa'u32),
  "lightslategray": color(0x778899'u32),
  "lightslategrey": color(0x778899'u32),
  "lightsteelblue": color(0xb0c4de'u32),
  "lightyellow": color(0xffffe0'u32),
  "lime": color(0x00ff00'u32),
  "limegreen": color(0x32cd32'u32),
  "linen": color(0xfaf0e6'u32),
  "magenta": color(0xff00ff'u32),
  "maroon": color(0x800000'u32),
  "mediumaquamarine": color(0x66cdaa'u32),
  "mediumblue": color(0x0000cd'u32),
  "mediumorchid": color(0xba55d3'u32),
  "mediumpurple": color(0x9370db'u32),
  "mediumseagreen": color(0x3cb371'u32),
  "mediumslateblue": color(0x7b68ee'u32),
  "mediumspringgreen": color(0x00fa9a'u32),
  "mediumturquoise": color(0x48d1cc'u32),
  "mediumvioletred": color(0xc71585'u32),
  "midnightblue": color(0x191970'u32),
  "mintcream": color(0xf5fffa'u32),
  "mistyrose": color(0xffe4e1'u32),
  "moccasin": color(0xffe4b5'u32),
  "navajowhite": color(0xffdead'u32),
  "navy": color(0x000080'u32),
  "oldlace": color(0xfdf5e6'u32),
  "olive": color(0x808000'u32),
  "olivedrab": color(0x6b8e23'u32),
  "orange": color(0xffa500'u32),
  "orangered": color(0xff4500'u32),
  "orchid": color(0xda70d6'u32),
  "palegoldenrod": color(0xeee8aa'u32),
  "palegreen": color(0x98fb98'u32),
  "paleturquoise": color(0xafeeee'u32),
  "palevioletred": color(0xdb7093'u32),
  "papayawhip": color(0xffefd5'u32),
  "peachpuff": color(0xffdab9'u32),
  "peru": color(0xcd853f'u32),
  "pink": color(0xffc0cb'u32),
  "plum": color(0xdda0dd'u32),
  "powderblue": color(0xb0e0e6'u32),
  "purple": color(0x800080'u32),
  "rebeccapurple": color(0x663399'u32),
  "red": color(0xff0000'u32),
  "rosybrown": color(0xbc8f8f'u32),
  "royalblue": color(0x4169e1'u32),
  "saddlebrown": color(0x8b4513'u32),
  "salmon": color(0xfa8072'u32),
  "sandybrown": color(0xf4a460'u32),
  "seagreen": color(0x2e8b57'u32),
  "seashell": color(0xfff5ee'u32),
  "sienna": color(0xa0522d'u32),
  "silver": color(0xc0c0c0'u32),
  "skyblue": color(0x87ceeb'u32),
  "slateblue": color(0x6a5acd'u32),
  "slategray": color(0x708090'u32),
  "slategrey": color(0x708090'u32),
  "snow": color(0xfffafa'u32),
  "springgreen": color(0x00ff7f'u32),
  "steelblue": color(0x4682b4'u32),
  "tan": color(0xd2b48c'u32),
  "teal": color(0x008080'u32),
  "thistle": color(0xd8bfd8'u32),
  "tomato": color(0xff6347'u32),
  "transparent": Vec4(x: 0, y: 0, z: 0, w: 0),
  "turquoise": color(0x40e0d0'u32),
  "violet": color(0xee82ee'u32),
  "wheat": color(0xf5deb3'u32),
  "white": color(0xffffff'u32),
  "whitesmoke": color(0xf5f5f5'u32),
  "yellow": color(0xffff00'u32),
  "yellowgreen": color(0x9acd32'u32),
}

proc color*(hex: string): Vec4 =
  let
    start = if hex.len > 0 and hex[0] == '#': 1 else: 0
    size = hex.len - start

  if start == 0 and hex[0].ord > '9'.ord:
    let name = hex.toLowerAscii()
    for entry in webColorMap:
      if name == entry[0]:
        return entry[1]

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
