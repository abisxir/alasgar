import math

import ../aljebra

type
  Pack2x16S{.union.} = object
    data: array[2, int16]
    converted: uint32
  Pack2x16U{.union.} = object
    data: array[2, uint16]
    converted: uint32
  Pack4x8U{.union.} = object
    data: array[4, byte]
    converted: uint32

func packSnorm2x16*(a, b: float32): uint32 =
  var u: Pack2x16S
  u.data[0] = round(clamp(a, -1, 1) * 32767'f32).int16
  u.data[1] = round(clamp(b, -1, 1) * 32767'f32).int16
  result = u.converted

func packSnorm2x16*(v: Vec2): uint32 = packSnorm2x16(v.x, v.y)

func unpackSnorm2x16*(v: uint32): Vec2 =
  var u: Pack2x16S
  u.converted = v
  result = vec2(u.data[0].float32, u.data[0].float32) * 3.0518509475997192297128208258309e-5'f32

func packUnorm2x16*(a, b: float32): uint32 =
  var u: Pack2x16U
  u.data[0] = round(clamp(a, -1, 1) * 65535'f32).uint16
  u.data[1] = round(clamp(b, -1, 1) * 65535'f32).uint16
  result = u.converted

func packUnorm2x16*(v: Vec2): uint32 = packSnorm2x16(v.x, v.y)

func unpackUnorm2x16*(v: uint32): Vec2 =
  var u: Pack2x16U
  u.converted = v
  result = vec2(u.data[0].float32, u.data[0].float32) * 1.5259021896696421759365224689097e-5'f32

func packUnorm4x8*(a, b, c, d: float32): uint32 =
  var u: Pack4x8U
  u.data[0] = round(clamp(a, 0, 1) * 255'f32).byte
  u.data[1] = round(clamp(b, 0, 1) * 255'f32).byte
  u.data[2] = round(clamp(c, 0, 1) * 255'f32).byte
  u.data[3] = round(clamp(d, 0, 1) * 255'f32).byte
  result = u.converted

func packUnorm4x8*(v: Vec4): uint32 = packUnorm4x8(v.x, v.y, v.z, v.w)

func unpackUnorm4x8*(v: uint32): Vec4 =
  var u: Pack4x8U
  u.converted = v
  result = vec4(u.data[0].float32, u.data[1].float32, u.data[2].float32, u.data[
      3].float32) * 0.0039215686274509803921568627451'f32
