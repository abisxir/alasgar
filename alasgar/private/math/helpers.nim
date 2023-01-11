import strformat
import math
import hashes
import random

export random, hashes, strformat, math

# Defines epsilon
const EPSILON* = 0.0000001'f32

func sign*(v: float32): float32 =
    ## Returns the sign of a number, -1 or 1.
    if v >= 0:
        return 1.0
    return -1.0

func inverseLerp*(a, b, v: float32): float32 = (v - a) / (b - a)
func lerp*(a, b, v: float32): float32 = a * (1.0 - v) + b * v
func map*(x, A, B, C, D: float32): float32 = (x - A) / (B - A) * (D - C) + C
