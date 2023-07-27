import helpers
import types
import vec3

type Vec4* = object
    x*: float32
    y*: float32
    z*: float32
    w*: float32

func vec4*(x, y, z, w: float32): Vec4 =
    result.x = x
    result.y = y
    result.z = z
    result.w = w

func `+`*(a: Vec4, b: Vec4): Vec4 =
    result.x = a.x + b.x
    result.y = a.y + b.y
    result.z = a.z + b.z
    result.w = a.w + b.w

func `-`*(a: Vec4, b: Vec4): Vec4 =
    result.x = a.x - b.x
    result.y = a.y - b.y
    result.z = a.z - b.z
    result.w = a.w - b.w

func `-`*(a: Vec4): Vec4 =
    result.x = -a.x
    result.y = -a.y
    result.z = -a.z
    result.w = -a.w

func `*`*(a: Vec4, b: float32): Vec4 =
    result.x = a.x * b
    result.y = a.y * b
    result.z = a.z * b
    result.w = a.w * b

func `*`*(a: float32, b: Vec4): Vec4 =
    b * a

func `/`*(a: Vec4, b: float32): Vec4 =
    result.x = a.x / b
    result.y = a.y / b
    result.z = a.z / b
    result.w = a.w / b

func `/`*(a: float32, b: Vec4): Vec4 =
    result.x = a / b.x
    result.y = a / b.y
    result.z = a / b.z
    result.w = a / b.w

func `+=`*(a: var Vec4, b: Vec4) =
    a.x += b.x
    a.y += b.y
    a.z += b.z
    a.w += b.w

func `-=`*(a: var Vec4, b: Vec4) =
    a.x -= b.x
    a.y -= b.y
    a.z -= b.z
    a.w -= b.w

func `*=`*(a: var Vec4, b: float32) =
    a.x *= b
    a.y *= b
    a.z *= b
    a.w *= b

func `/=`*(a: var Vec4, b: float32) =
    a.x /= b
    a.y /= b
    a.z /= b
    a.w /= b

func zero*(a: var Vec4) =
    a.x = 0
    a.y = 0
    a.z = 0
    a.w = 0

func hash*(a: Vec4): Hash =
    hash((a.x, a.y, a.z, a.w))

func `[]`*(a: Vec4, i: int): float32 =
    assert(i == 0 or i == 1 or i == 2)
    if i == 0:
        return a.x
    elif i == 1:
        return a.y
    elif i == 2:
        return a.z
    elif i == 3:
        return a.w

func `[]=`*(a: var Vec4, i: int, b: float32) =
    assert(i == 0 or i == 1 or i == 2)
    if i == 0:
        a.x = b
    elif i == 1:
        a.y = b
    elif i == 2:
        a.z = b
    elif i == 3:
        a.w = b

func lerp*(a: Vec4, b: Vec4, v: float32): Vec4 =
    a * (1.0 - v) + b * v

func xyz*(a: Vec4): Vec3 =
    vec3(a.x, a.y, a.z)

func `$`*(a: Vec4): string =
    &"({a.x:.8f}, {a.y:.8f}, {a.z:.8f}, {a.w:.8f})"

func vec3*(a: Vec2, z = 0.0): Vec3 =
    vec3(a.x, a.y, z)

func vec4*(a: Vec3, w = 0.0): Vec4 =
    vec4(a.x, a.y, a.z, w)

func vec4*(a: Vec2, z = 0.0, w = 0.0): Vec4 =
    vec4(a.x, a.y, z, w)

func caddr*(v: var Vec4): ptr float32 = v.x.addr
