import random
import math
import strformat
import strutils
import sequtils
import tables

import chroma

import ports/opengl
import logger
import error
import aljebra/[helpers, vector, matrix, types, quat, sugar]

export logger, helpers, strformat, chroma, strutils, sequtils, opengl, error, helpers, vector, matrix, types, quat, sugar

# Extracts data out of the given pointer
template offsetOf*[T](p: ptr T, o: int): T = cast[ptr T](cast[ByteAddress](p) + (o * sizeof(T)))


# General funcs
proc halt*(message: string) = 
    logi message
    quit message

# Numeric utils
proc rand*(mi, mx: float32): float32 = rand(1'f32) * (mx - mi) + mi
proc rand*(mi, mx: int): int = rand(mx - mi) + mi

# List utils
template delete*[T](l: var seq[T], item: T) = 
    var idx = find(l, item)
    if idx >= 0:
        delete(l, idx) 

# Color utils
func `bytes`*(c: Color): (uint8, uint8, uint8, uint8) =
    result = ((c.r * 255.0).uint8, (c.g * 255.0).uint8, (c.b * 255.0).uint8, (c.a * 255.0).uint8)
func `vec3`*(c: Color): Vec3 = vec3(c.r, c.g, c.b)
func rgb*(r, g, b: float): Color = color(r, g, b, 1.0)
func rgba*(r, g, b, a: float): Color = color(r, g, b, a)

proc randomColor*(): Color = 
    result = color(rand(1.0), rand(1.0), rand(1.0))

let COLOR_BLACK*: Color = color(0, 0, 0)
let COLOR_WHITE*: Color = color(1, 1, 1)
let COLOR_MILK*: Color = color(0.8, 0.8, 0.75)
let COLOR_GREY*: Color = color(0.5, 0.5, 0.5)
let COLOR_RED*: Color = color(1, 0, 0)
let COLOR_GREEN*: Color = color(0, 1, 0)
let COLOR_BLUE*: Color = color(0, 0, 1)
let COLOR_YELLOW*: Color = color(1, 1, 0)

proc clear*[T](t: var seq[T]) = setLen[T](t, 0)

template findIt*[T](s: openArray[T], pred: untyped): T = 
    for it {.inject.}  in s:
        if pred:
            return it

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
    result = vec4(u.data[0].float32, u.data[1].float32, u.data[2].float32, u.data[3].float32) * 0.0039215686274509803921568627451'f32

