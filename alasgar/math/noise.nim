import random
import math

const IYMAX = 512;
const IXMAX = 512;
const SEED = 1356 * 9 * 21

type
    GradientArray* = array[IYMAX, array[IXMAX, array[2, float]]]

var gradient: GradientArray

func lerp(a0, a1, w: float32): float32 = (1 - w) * a0 + w * a1

# Computes the dot product of the distance and gradient vectors.
proc dotGridGradient(gradient: var GradientArray, ix, iy: int32, x, y: float32): float32 =
   # Compute the distance vector
    let dx = x - ix.float32
    let dy = y - iy.float32

    let nx = if ix >= 0: ix else: IXMAX + ix
    let ny = if iy >= 0: iy else: IYMAX + iy

    # Compute the dot-product
    result = (dx * gradient[ny][nx][0] + dy * gradient[ny][nx][1])

# Compute Perlin noise at coordinates x, y
proc perlin(x, y: float32): float32 =
    let x0 = x.int32
    let x1 = x0 + 1
    let y0 = y.int32
    let y1 = y0 + 1

    # Determine interpolation weights
    # Could also use higher order polynomial/s-curve here
    let sx = x - x0.float32
    let sy = y - y0.float32

    # Interpolate between grid point gradients
    var n0, n1, ix0, ix1: float32

    n0 = dotGridGradient(gradient, x0, y0, x, y)
    n1 = dotGridGradient(gradient, x1, y0, x, y)
    ix0 = lerp(n0, n1, sx)

    n0 = dotGridGradient(gradient, x0, y1, x, y)
    n1 = dotGridGradient(gradient, x1, y1, x, y)
    ix1 = lerp(n0, n1, sx)

    result = lerp(ix0, ix1, sy)

randomize(SEED)
for y in low(gradient)..high(gradient):
    for x in low(gradient[y])..high(gradient[y]):
        let r = rand(2 * PI)
        gradient[y][x][0] = sin(r)
        gradient[y][x][1] = cos(r)