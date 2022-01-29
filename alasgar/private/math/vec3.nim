import types
import helpers
import vec2

export types

func vec3*(x, y, z: float32): Vec3 =
    result.x = x
    result.y = y
    result.z = z

func vec3*(a: Vec3): Vec3 =
    result.x = a.x
    result.y = a.y
    result.z = a.z

func vec3*(a: float32): Vec3 =
    result.x = a
    result.y = a
    result.z = a

const X_DIR* = vec3(1.0, 0.0, 0.0)
const Y_DIR* = vec3(0.0, 1.0, 0.0)
const Z_DIR* = vec3(0.0, 0.0, 1.0)

func `+`*(a: Vec3, b: Vec3): Vec3 =
    result.x = a.x + b.x
    result.y = a.y + b.y
    result.z = a.z + b.z

func `-`*(a: Vec3, b: Vec3): Vec3 =
    result.x = a.x - b.x
    result.y = a.y - b.y
    result.z = a.z - b.z

func `-`*(a: Vec3): Vec3 =
    result.x = -a.x
    result.y = -a.y
    result.z = -a.z

func `*`*(a: Vec3, b: float32): Vec3 =
    result.x = a.x * b
    result.y = a.y * b
    result.z = a.z * b

func `*`*(a, b: Vec3): Vec3 =
    result.x = a.x * b.x
    result.y = a.y * b.y
    result.z = a.z * b.z

func `*`*(a: float32, b: Vec3): Vec3 =
    b * a

func `/`*(a: Vec3, b: float32): Vec3 =
    result.x = a.x / b
    result.y = a.y / b
    result.z = a.z / b

func `/`*(a: float32, b: Vec3): Vec3 =
    result.x = a / b.x
    result.y = a / b.y
    result.z = a / b.z

func `+=`*(a: var Vec3, b: Vec3) =
    a.x += b.x
    a.y += b.y
    a.z += b.z

func `-=`*(a: var Vec3, b: Vec3) =
    a.x -= b.x
    a.y -= b.y
    a.z -= b.z

func `*=`*(a: var Vec3, b: float32) =
    a.x *= b
    a.y *= b
    a.z *= b

func `/=`*(a: var Vec3, b: float32) =
    a.x /= b
    a.y /= b
    a.z /= b

func zero*(a: var Vec3) =
    a.x = 0
    a.y = 0
    a.z = 0

func `-`*(a: var Vec3): Vec3 =
    result.x = -a.x
    result.y = -a.y
    result.z = -a.z

func hash*(a: Vec3): Hash =
    hash((a.x, a.y, a.z))

func lengthSq*(a: Vec3): float32 =
    a.x * a.x + a.y * a.y + a.z * a.z

func length*(a: Vec3): float32 =
    sqrt(a.lengthSq)

func `length=`*(a: var Vec3, b: float32) =
    a *= b / a.length

func floor*(a: Vec3): Vec3 =
    vec3(floor(a.x), floor(a.y), floor(a.z))

func round*(a: Vec3): Vec3 =
    vec3(round(a.x), round(a.y), round(a.z))

func ceil*(a: Vec3): Vec3 =
    vec3(ceil(a.x), ceil(a.y), ceil(a.z))

func normalize*(a: Vec3): Vec3 =
    a / sqrt(a.x*a.x + a.y*a.y + a.z*a.z)

func cross*(a: Vec3, b: Vec3): Vec3 =
    result.x = a.y*b.z - a.z*b.y
    result.y = a.z*b.x - a.x*b.z
    result.z = a.x*b.y - a.y*b.x

func computeNormal*(a, b, c: Vec3): Vec3 =
    cross(c - b, b - a).normalize()

func dot*(a: Vec3, b: Vec3): float32 =
    a.x*b.x + a.y*b.y + a.z*b.z

func dir*(at: Vec3, to: Vec3): Vec3 =
  (at - to).normalize()

func dist*(at: Vec3, to: Vec3): float32 =
    (at - to).length

func distSq*(at: Vec3, to: Vec3): float32 =
    (at - to).lengthSq

func lerp*(a: Vec3, b: Vec3, v: float32): Vec3 =
    a * (1.0 - v) + b * v

func quantize*(v: Vec3, n: float32): Vec3 =
    result.x = sign(v.x) * floor(abs(v.x) / n) * n
    result.y = sign(v.y) * floor(abs(v.y) / n) * n
    result.z = sign(v.z) * floor(abs(v.z) / n) * n

func angleBetween*(a, b: Vec3): float32 =
    var dot = dot(a, b)
    dot = dot / (a.length * b.length)
    arccos(dot)

func `[]`*(a: Vec3, i: int): float32 =
    assert(i == 0 or i == 1 or i == 2)
    if i == 0:
        return a.x
    elif i == 1:
        return a.y
    elif i == 2:
        return a.z

func `[]=`*(a: var Vec3, i: int, b: float32) =
    assert(i == 0 or i == 1 or i == 2)
    if i == 0:
        a.x = b
    elif i == 1:
        a.y = b
    elif i == 2:
        a.z = b

func xy*(a: Vec3): Vec2 =
    vec2(a.x, a.y)

func xz*(a: Vec3): Vec2 =
    vec2(a.x, a.z)

func yx*(a: Vec3): Vec2 =
    vec2(a.y, a.x)

func yz*(a: Vec3): Vec2 =
    vec2(a.y, a.z)

func zx*(a: Vec3): Vec2 =
    vec2(a.y, a.x)

func zy*(a: Vec3): Vec2 =
    vec2(a.z, a.y)

func almostEquals*(a, b: Vec3, precision = 1e-6): bool =
    let c = a - b
    abs(c.x) < precision and abs(c.y) < precision and abs(c.z) < precision

proc randVec3*(): Vec3 =
    let
        u = rand(0.0 .. 1.0)
        v = rand(0.0 .. 1.0)
        th = 2 * PI * u
        ph = arccos(2 * v - 1)
    vec3(
        cos(th) * sin(ph),
        sin(th) * sin(ph),
        cos(ph)
    )

func `$`*(a: Vec3): string =
  &"({a.x:.8f}, {a.y:.8f}, {a.z:.8f})"


let VEC3_ZERO* = vec3(0, 0, 0)
let VEC3_ONE* = vec3(1, 1, 1)
let VEC3_RIGHT* = vec3(1, 0, 0)
let VEC3_LEFT* = vec3(-1, 0, 0)
let VEC3_UP* = vec3(0, 1, 0)
let VEC3_DOWN* = vec3(0, -1, 0)
let VEC3_FORWARD* = vec3(0, 0, -1)
let VEC3_BACK* = vec3(0, 0, 1)

func caddr*(v: var Vec3): ptr float32 = v.x.addr
func caddr*(v: var Vec2): ptr float32 = v.x.addr