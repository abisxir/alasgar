import math

import common, vec2, vec3, vec4

const
  INV_255* = 1.0'f32 / 255.0'f32
  INV_127* = 1.0'f32 / 127.0'f32
  INV_65535* = 1.0'f32 / 65535.0'f32
  INV_32767* = 1.0'f32 / 32767.0'f32

# Convention notes:
# - Unorm values are exact (0..255/65535 map 0.0..1.0).
# - Snorm follows the GL convention: round(v * 127) for 8-bit, so -1.0 packs
#   to -127 and unpacks back to exactly -1.0. The reserved -128 maps to
#   -1.00787, clamped back to -1.0 on unpack.
# - Packed multichannel formats are little-endian: the first component
#   occupies the least-significant bits.
# - NaN or out-of-range values are clamped; NaN packs to 0 rather than
#   crashing on the integer conversion.

func packRange(value: float32, lo, hi: float32): float32 =
  if value != value:
    0.0
  else:
    clamp(value, lo, hi)

func packUnorm8*(value: float32): byte = round(packRange(value, 0'f32, 1'f32) * 255'f32).byte
func packSnorm8*(value: float32): int8 = round(packRange(value, -1'f32, 1'f32) * 127'f32).int8
func packUnorm16*(value: float32): uint16 = round(packRange(value, 0'f32, 1'f32) * 65535'f32).uint16
func packSnorm16*(value: float32): int16 = round(packRange(value, -1'f32, 1'f32) * 32767'f32).int16

func unpackUnorm8*(value: byte): float32 = value.float32 * INV_255
func unpackSnorm8*(value: int8): float32 = clamp(value.float32 * INV_127, -1'f32, 1'f32)
func unpackUnorm16*(value: uint16): float32 = value.float32 * INV_65535
func unpackSnorm16*(value: int16): float32 = clamp(value.float32 * INV_32767, -1'f32, 1'f32)

func packSnorm2x8*(a, b: float32): uint16 =
  (packSnorm8(a).uint16 and 0xff) or ((packSnorm8(b).uint16 and 0xff) shl 8)

func packSnorm2x8*(v: Vec2): uint16 = packSnorm2x8(v.x, v.y)

func unpackSnorm2x8*(v: uint16): Vec2 =
  vec2(
    unpackSnorm8(cast[int8](v and 0xff)),
    unpackSnorm8(cast[int8]((v shr 8) and 0xff)),
  )

func packUnorm2x8*(a, b: float32): uint16 =
  packUnorm8(a).uint16 or (packUnorm8(b).uint16 shl 8)

func packUnorm2x8*(v: Vec2): uint16 = packUnorm2x8(v.x, v.y)

func unpackUnorm2x8*(v: uint16): Vec2 =
  vec2(
    unpackUnorm8(byte(v and 0xff)),
    unpackUnorm8(byte((v shr 8) and 0xff)),
  )

func packSnorm2x16*(a, b: float32): uint32 =
  (packSnorm16(a).uint32 and 0xffff) or ((packSnorm16(b).uint32 and 0xffff) shl 16)

func packSnorm2x16*(v: Vec2): uint32 = packSnorm2x16(v.x, v.y)

func unpackSnorm2x16*(v: uint32): Vec2 =
  vec2(
    unpackSnorm16(cast[int16](v and 0xffff)),
    unpackSnorm16(cast[int16]((v shr 16) and 0xffff)),
  )

func packUnorm2x16*(a, b: float32): uint32 =
  packUnorm16(a).uint32 or (packUnorm16(b).uint32 shl 16)

func packUnorm2x16*(v: Vec2): uint32 = packUnorm2x16(v.x, v.y)

func unpackUnorm2x16*(v: uint32): Vec2 =
  vec2(
    unpackUnorm16(uint16(v and 0xffff)),
    unpackUnorm16(uint16((v shr 16) and 0xffff)),
  )

func packSnorm3x8*(a, b, c: float32): uint32 =
  (packSnorm8(a).uint32 and 0xff) or
    ((packSnorm8(b).uint32 and 0xff) shl 8) or
    ((packSnorm8(c).uint32 and 0xff) shl 16)

func packSnorm3x8*(v: Vec3): uint32 = packSnorm3x8(v.x, v.y, v.z)

func unpackSnorm3x8*(v: uint32): Vec3 =
  vec3(
    unpackSnorm8(cast[int8](v and 0xff)),
    unpackSnorm8(cast[int8]((v shr 8) and 0xff)),
    unpackSnorm8(cast[int8]((v shr 16) and 0xff)),
  )

func packUnorm3x8*(a, b, c: float32): uint32 =
  packUnorm8(a).uint32 or
    (packUnorm8(b).uint32 shl 8) or
    (packUnorm8(c).uint32 shl 16)

func packUnorm3x8*(v: Vec3): uint32 = packUnorm3x8(v.x, v.y, v.z)

func unpackUnorm3x8*(v: uint32): Vec3 =
  vec3(
    unpackUnorm8(byte(v and 0xff)),
    unpackUnorm8(byte((v shr 8) and 0xff)),
    unpackUnorm8(byte((v shr 16) and 0xff)),
  )

func packUnorm4x8*(a, b, c, d: float32): uint32 =
  packUnorm8(a).uint32 or
    (packUnorm8(b).uint32 shl 8) or
    (packUnorm8(c).uint32 shl 16) or
    (packUnorm8(d).uint32 shl 24)

func packUnorm4x8*(v: Vec4): uint32 = packUnorm4x8(v.x, v.y, v.z, v.w)

func unpackUnorm4x8*(v: uint32): Vec4 =
  vec4(
    unpackUnorm8(byte(v and 0xff)),
    unpackUnorm8(byte((v shr 8) and 0xff)),
    unpackUnorm8(byte((v shr 16) and 0xff)),
    unpackUnorm8(byte((v shr 24) and 0xff)),
  )

func packSnorm4x8*(a, b, c, d: float32): uint32 =
  (packSnorm8(a).uint32 and 0xff) or
    ((packSnorm8(b).uint32 and 0xff) shl 8) or
    ((packSnorm8(c).uint32 and 0xff) shl 16) or
    ((packSnorm8(d).uint32 and 0xff) shl 24)

func packSnorm4x8*(v: Vec4): uint32 = packSnorm4x8(v.x, v.y, v.z, v.w)

func unpackSnorm4x8*(v: uint32): Vec4 =
  vec4(
    unpackSnorm8(cast[int8](v and 0xff)),
    unpackSnorm8(cast[int8]((v shr 8) and 0xff)),
    unpackSnorm8(cast[int8]((v shr 16) and 0xff)),
    unpackSnorm8(cast[int8]((v shr 24) and 0xff)),
  )

func normal4f*(a, b, c, d: float32): uint32 = packSnorm4x8(a, b, c, d)
func normal4f*(value: Vec4): uint32 = packSnorm4x8(value)

when isMainModule:
  doAssert packUnorm8(0.0) == 0
  doAssert packUnorm8(0.5) == 128
  doAssert packUnorm8(1.0) == 255
  doAssert packUnorm8(NaN) == 0
  doAssert packUnorm8(2.0) == 255
  doAssert packUnorm8(-1.0) == 0
  doAssert unpackUnorm8(0) == 0.0
  doAssert unpackUnorm8(255) == 1.0
  doAssert abs(unpackUnorm8(128) - 0.5019608) < 1e-6

  doAssert packSnorm8(-1.0) == -127
  doAssert packSnorm8(0.0) == 0
  doAssert packSnorm8(1.0) == 127
  doAssert packSnorm8(NaN) == 0
  doAssert unpackSnorm8(-128) == -1.0
  doAssert unpackSnorm8(127) == 1.0
  doAssert unpackSnorm8(-127) == -1.0
  doAssert abs(unpackSnorm8(64) - 0.5039370) < 1e-6

  doAssert packUnorm16(0.0) == 0
  doAssert packUnorm16(1.0) == 65535
  doAssert unpackUnorm16(65535) == 1.0
  doAssert packSnorm16(-1.0) == -32767
  doAssert packSnorm16(1.0) == 32767
  doAssert unpackSnorm16(-32768) == -1.0
  doAssert unpackSnorm16(32767) == 1.0

  doAssert packUnorm2x8(0.0, 1.0) == 0xff00'u16
  doAssert unpackUnorm2x8(0xff00'u16).x == 0.0
  doAssert unpackUnorm2x8(0xff00'u16).y == 1.0
  doAssert packSnorm2x8(-1.0, 1.0) == 0x7f81'u16
  doAssert unpackSnorm2x8(0x7f81'u16).x == -1.0
  doAssert unpackSnorm2x8(0x7f81'u16).y == 1.0

  doAssert packUnorm2x16(0.0, 1.0) == 0xffff0000'u32
  doAssert unpackUnorm2x16(0xffff0000'u32).x == 0.0
  doAssert unpackUnorm2x16(0xffff0000'u32).y == 1.0
  doAssert packSnorm2x16(-1.0, 1.0) == 0x7fff8001'u32
  doAssert unpackSnorm2x16(0x7fff8001'u32).x == -1.0
  doAssert unpackSnorm2x16(0x7fff8001'u32).y == 1.0

  doAssert packUnorm3x8(1.0, 0.5, 0.0) == 0x0080ff'u32
  doAssert unpackUnorm3x8(0x0080ff'u32).x == 1.0
  doAssert unpackUnorm3x8(0x0080ff'u32).y == 0.5019608'f32
  doAssert unpackUnorm3x8(0x0080ff'u32).z == 0.0
  doAssert packSnorm3x8(1.0, -1.0, 0.0) == 0x0000817f'u32
  doAssert unpackSnorm3x8(0x0000817f'u32).y == -1.0

  doAssert packUnorm4x8(1.0, 0.5, 0.0, 1.0) == 0xff0080ff'u32
  doAssert unpackUnorm4x8(0xff0080ff'u32).x == 1.0
  doAssert unpackUnorm4x8(0xff0080ff'u32).y == 0.5019608'f32
  doAssert unpackUnorm4x8(0xff0080ff'u32).w == 1.0
  doAssert packSnorm4x8(1.0, -1.0, 0.0, 0.5) == 0x4000817f'u32
  doAssert unpackSnorm4x8(0x4000817f'u32).x == 1.0
  doAssert unpackSnorm4x8(0x4000817f'u32).y == -1.0
  doAssert unpackSnorm4x8(0x4000817f'u32).w == 64.0'f32 * INV_127

  doAssert normal4f(1.0, -1.0, 0.0, 0.5) == packSnorm4x8(1.0, -1.0, 0.0, 0.5)

  var r: float32 = 0.0
  while r <= 1.0:
    doAssert abs(unpackUnorm8(packUnorm8(r)) - r) <= 1.0 / 255.0
    doAssert abs(unpackSnorm8(packSnorm8(r)) - r) <= 1.0 / 127.0
    doAssert abs(unpackUnorm16(packUnorm16(r)) - r) <= 1.0 / 65535.0
    doAssert abs(unpackSnorm16(packSnorm16(r)) - r) <= 1.0 / 32767.0
    r += 0.001
