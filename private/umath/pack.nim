import math

import common, vec2, vec4

const
  INV_255* = 1.0'f32 / 255.0'f32
  INV_127* = 1.0'f32 / 127.0'f32
  INV_65535* = 1.0'f32 / 65535.0'f32
  INV_32767* = 1.0'f32 / 32767.0'f32

func packUnorm8*(value: float32): byte = round(clamp(value, 0'f32, 1'f32) * 255'f32).byte
func packSnorm8*(value: float32): int8 = round(clamp(value, -1'f32, 1'f32) * 127'f32).int8
func packUnorm16*(value: float32): uint16 = round(clamp(value, 0'f32, 1'f32) * 65535'f32).uint16
func packSnorm16*(value: float32): int16 = round(clamp(value, -1'f32, 1'f32) * 32767'f32).int16

func unpackUnorm8*(value: byte): float32 = value.float32 * INV_255
func unpackSnorm8*(value: int8): float32 = value.float32 * INV_127
func unpackUnorm16*(value: uint16): float32 = value.float32 * INV_65535
func unpackSnorm16*(value: int16): float32 = value.float32 * INV_32767

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
