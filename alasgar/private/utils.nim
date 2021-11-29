import random
import math
import strformat
import strutils
import sequtils
import re

import chroma

import math/helpers
import math/mat4
import math/vec2
import math/vec3
import math/vec4
import math/quat
import logger

export logger, helpers, quat, mat4, vec2, vec3, vec4, strformat, chroma, strutils, sequtils

# General funcs
proc halt*(message: string) = 
    logi message
    quit message

# Numeric utils
proc randRange*(mi, mx: float32): float32 = rand(1'f32) * (mx - mi) + mi

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

proc randColor*(): Color = 
    let v = normalize(randVec3())
    result = color(v.x, v.y, v.z)

let COLOR_BLACK*: Color = color(0, 0, 0)
let COLOR_WHITE*: Color = color(1, 1, 1)
let COLOR_MILK*: Color = color(0.8, 0.8, 0.75)
let COLOR_GREY*: Color = color(0.5, 0.5, 0.5)
let COLOR_RED*: Color = color(1, 0, 0)
let COLOR_GREEN*: Color = color(0, 1, 0)
let COLOR_BLUE*: Color = color(0, 0, 1)
let COLOR_YELLOW*: Color = color(1, 1, 0)

proc clear*[T](t: var seq[T]) = setLen[T](t, 0)
func isFilename*(fullpath: string): bool = not isEmptyOrWhitespace(fullpath) and match(fullpath, re"^[\w,\s-]+\.[A-Za-z]{3,4}$")

template findIt*[T](s: openArray[T], pred: untyped): T = 
    for it {.inject.}  in s:
        if pred:
            return it
