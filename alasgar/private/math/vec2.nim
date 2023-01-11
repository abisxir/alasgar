import types
import helpers

export types

func vec2*(x, y: float32): Vec2 =
    result.x = x
    result.y = y

func vec2*(x: float32): Vec2 = vec2(x, x)
    
func vec2*(a: Vec2): Vec2 =
    result.x = a.x
    result.y = a.y

func `+`*(a: Vec2, b: Vec2): Vec2 =
    result.x = a.x + b.x
    result.y = a.y + b.y

func `-`*(a: Vec2, b: Vec2): Vec2 =
    result.x = a.x - b.x
    result.y = a.y - b.y

func `*`*(a, b: Vec2): Vec2 =
    result.x = a.x * b.x
    result.y = a.y * b.y

func `*`*(a: Vec2, b: float32): Vec2 =
    result.x = a.x * b
    result.y = a.y * b

func `*`*(a: float32, b: Vec2): Vec2 =
    b * a

func `/`*(a: Vec2, b: float32): Vec2 =
    result.x = a.x / b
    result.y = a.y / b

func `+=`*(a: var Vec2, b: Vec2) =
    a.x += b.x
    a.y += b.y

func `-=`*(a: var Vec2, b: Vec2) =
    a.x -= b.x
    a.y -= b.y

func `*=`*(a: var Vec2, b: float32) =
    a.x *= b
    a.y *= b

func `/=`*(a: var Vec2, b: float32) =
    a.x /= b
    a.y /= b

func zero*(a: var Vec2) =
    a.x = 0
    a.y = 0

func `-`*(a: Vec2): Vec2 =
    result.x = -a.x
    result.y = -a.y

func hash*(a: Vec2): Hash =
    hash((a.x, a.y))

func lengthSq*(a: Vec2): float32 =
    a.x * a.x + a.y * a.y

func length*(a: Vec2): float32 =
    sqrt(a.lengthSq)

func `length=`*(a: var Vec2, b: float32) =
    a *= b / a.length

func normalize*(a: Vec2): Vec2 =
    a / a.length

func dot*(a: Vec2, b: Vec2): float32 =
    a.x*b.x + a.y*b.y

func dir*(at: Vec2, to: Vec2): Vec2 =
    (at - to).normalize()

func dir*(th: float32): Vec2 =
    vec2(cos(th), sin(th))

func dist*(at: Vec2, to: Vec2): float32 =
    (at - to).length

func distSq*(at: Vec2, to: Vec2): float32 =
    (at - to).lengthSq

func lerp*(a: Vec2, b: Vec2, v: float32): Vec2 =
    a * (1.0 - v) + b * v

func quantize*(v: Vec2, n: float32): Vec2 =
    result.x = sign(v.x) * floor(abs(v.x) / n) * n
    result.y = sign(v.y) * floor(abs(v.y) / n) * n

func inRect*(v: Vec2, a: Vec2, b: Vec2): bool =
    ## Check to see if v is inside a rectange formed by a and b.
    ## It does not matter how a and b are arranged.
    let
        min = vec2(min(a.x, b.x), min(a.y, b.y))
        max = vec2(max(a.x, b.x), max(a.y, b.y))
    v.x > min.x and v.x < max.x and v.y > min.y and v.y < max.y

func `[]`*(a: Vec2, i: int): float32 =
    assert(i == 0 or i == 1)
    if i == 0:
        return a.x
    elif i == 1:
        return a.y

func `[]=`*(a: var Vec2, i: int, b: float32) =
    assert(i == 0 or i == 1)
    if i == 0:
        a.x = b
    elif i == 1:
        a.y = b

proc randVec2*(): Vec2 =
    let a = rand(PI*2)
    let v = rand(1.0)
    vec2(cos(a)*v, sin(a)*v)

func `$`*(a: Vec2): string =
    &"({a.x:.4f}, {a.y:.4f})"

let VEC2_ZERO* = vec2(0, 0)
let VEC2_ONE* = vec2(1, 1)
let VEC2_RIGHT* = vec2(1, 0)
let VEC2_LEFT* = vec2(-1, 0)
let VEC2_UP* = vec2(0, 1)
let VEC2_DOWN* = vec2(0, -1)

func `iWidth`*(a: Vec2): int32 = a.x.int32
func `iHeight`*(a: Vec2): int32 = a.y.int32
