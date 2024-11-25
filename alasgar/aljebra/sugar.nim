import helpers, types, vector

# Scalar
func inverseLerp*(a, b, v: float32): float32 = (v - a) / (b - a)
func map*(x, A, B, C, D: float32): float32 = (x - A) / (B - A) * (D - C) + C

# Vec2
proc randomVec2*(): Vec2 =
    let 
        a = rand(PI*2)
        v = rand(1.0)
    vec2(cos(a)*v, sin(a)*v)

let VEC2_ZERO* = vec2(0, 0)
let VEC2_ONE* = vec2(1, 1)
let VEC2_RIGHT* = vec2(1, 0)
let VEC2_LEFT* = vec2(-1, 0)
let VEC2_UP* = vec2(0, 1)
let VEC2_DOWN* = vec2(0, -1)

func `iWidth`*[T: Vec2|IVec2|UVec2](a: T): int32 = a.x.int32
func `iHeight`*[T: Vec2|IVec2|UVec2](a: T): int32 = a.y.int32
func `width`*[T: Vec2|IVec2|UVec2](a: T): float32 = a.x.float32
func `height`*[T: Vec2|IVec2|UVec2](a: T): float32 = a.y.float32

func inRect*[T: Vec2|IVec2|UVec2](v, a, b: T): bool =
    ## Check to see if v is inside a rectange formed by a and b.
    ## It does not matter how a and b are arranged.
    let
        min = vec2(min(a.x, b.x), min(a.y, b.y))
        max = vec2(max(a.x, b.x), max(a.y, b.y))
    v.x > min.x and v.x < max.x and v.y > min.y and v.y < max.y

# Vec3
let VEC3_ZERO* = vec3(0, 0, 0)
let VEC3_ONE* = vec3(1, 1, 1)
let VEC3_RIGHT* = vec3(1, 0, 0)
let VEC3_LEFT* = vec3(-1, 0, 0)
let VEC3_UP* = vec3(0, 1, 0)
let VEC3_DOWN* = vec3(0, -1, 0)
let VEC3_FORWARD* = vec3(0, 0, -1)
let VEC3_BACK* = vec3(0, 0, 1)

# Swizzling
func `r`*(v: Vec3|Vec4): float32 = v.x
func `r=`*(v: var Vec3|Vec4, r: float32) = v.x = r
func `g`*(v: Vec3|Vec4): float32 = v.y
func `g=`*(v: var Vec3|Vec4, g: float32) = v.y = g
func `b`*(v: Vec3|Vec4): float32 = v.z
func `b=`*(v: var Vec3|Vec4, b: float32) = v.z = b
func `a`*(v: Vec4): float32 = v.w
func `a=`*(v: var Vec4, a: float32) = v.w = a
func `yzx`*(v: Vec3|Vec4): Vec3 = Vec3(x: v.z, y: v.z, z: v.y)
func `xyz`*(v: Vec3|Vec4): Vec3 = Vec3(x: v.x, y: v.y, z: v.z)
func `xyz=`*(v: var Vec4, o: Vec3) = (v.x = o.x;v.y = o.y;v.z = o.z)
func `zyx`*(v: Vec3|Vec4): Vec3 = Vec3(x: v.z, y: v.y, z: v.x)
func `zxy`*(v: Vec3|Vec4): Vec3 = Vec3(x: v.z, y: v.x, z: v.y)
func `xyx`*(v: Vec2|Vec3|Vec4): Vec3 = Vec3(x: v.x, y: v.y, z: v.x)
func `xyx=`*(v: var Vec4, o: Vec3) = (v.x = o.x;v.y = o.y;v.z = o.x)
func `rgba`*(v: Vec4): Vec4 = v
func `rgba=`*(v: var Vec4, o: Vec4) =
    v.x = o.x
    v.y = o.y
    v.z = o.z
    v.w = o.w
func `xy`*(v: Vec3|Vec4): Vec2 = Vec2(x: v.x, y: v.y)
func `xy=`*(v: var Vec3|Vec4, o: Vec2) = 
    v.x = o.x
    v.y = o.y
func `xz`*(v: Vec3|Vec4): Vec2 = Vec2(x: v.x, y: v.z)
func `xz=`*(v: var Vec3|Vec4, o: Vec2) = 
    v.x = o.x
    v.z = o.y
func `zw`*(v: Vec4): Vec2 = Vec2(x: v.z, y: v.w)
func `zw=`*(v: var Vec4, o: Vec2) = 
    v.z = o.x
    v.w = o.y
func `xx`*(v: Vec3|Vec4): Vec2 = Vec2(x: v.x)
func `xxx`*(v: Vec3|Vec4): Vec2 = Vec3(x: v.x)
func `rgb`*(v: Vec3|Vec4): Vec3 = v.xyz
func `rgb=`*(v: var Vec4, o: Vec3) = v.xyz = o


# GLSL
func step*(edge, x: float32): float32 = (if x < edge: 0.0 else: 1.0)
func step*(e1, e2: Vec2): Vec2 = vec2(step(e1.x, e2.x), step(e1.y, e2.y))
func step*(e1, e2: Vec3): Vec3 = vec3(step(e1.x, e2.x), step(e1.y, e2.y), step(e1.z, e2.z))
func step*(e1, e2: Vec4): Vec4 = vec4(step(e1.x, e2.x), step(e1.y, e2.y), step(e1.z, e2.z), step(e1.w, e2.w))
proc smoothstep*(edge0, edge1: float32, x: float32): float32 =
  let t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
  result = t * t * (3 - 2 * t)
proc smoothstep*(edge0, edge1: float32, x: Vec2): Vec2 =
  let t = clamp((x - edge0) / (edge1 - edge0), vec2(0.0), vec2(1.0))
  result = t * t * (3 - 2 * t)
proc smoothstep*(edge0, edge1: float32, x: Vec3): Vec3 =
  let t = clamp((x - edge0) / (edge1 - edge0), vec3(0.0), vec3(1.0))
  result = t * t * (3 - 2 * t)
proc smoothstep*(edge0, edge1: float32, x: Vec4): Vec4 =
  let t = clamp((x - edge0) / (edge1 - edge0), vec4(0.0), vec4(1.0))
  result = t * t * (3 - 2 * t)
proc smoothstep*(edge0, edge1, x: Vec2): Vec2 = 
  let t = clamp((x - edge0) / (edge1 - edge0), vec2(0.0), vec2(1.0))
  result = t * t * (3.0 - 2.0 * t)
proc smoothstep*(edge0, edge1, x: Vec3): Vec3 = 
  let t = clamp((x - edge0) / (edge1 - edge0), vec3(0.0), vec3(1.0))
  result = t * t * (3.0 - 2.0 * t)
proc smoothstep*(edge0, edge1, x: Vec4): Vec4 = 
  let t = clamp((x - edge0) / (edge1 - edge0), vec4(0.0), vec4(1.0))
  result = t * t * (3.0 - 2.0 * t)
proc refract*(i, n: Vec2; eta: float32): Vec2 =
  # For a given incident vector ``i``, surface normal ``n`` and ratio of indices of refraction, ``eta``, refract returns the refraction vector.
  let k = 1 - eta * eta * (1 - dot(n, i) * dot(n, i))
  if k >= 0.0:
    result = eta * i - (eta * dot(n, i) + sqrt(k)) * n
proc refract*(i, n: Vec3; eta: float32): Vec3 =
  # For a given incident vector ``i``, surface normal ``n`` and ratio of indices of refraction, ``eta``, refract returns the refraction vector.
  let k = 1 - eta * eta * (1 - dot(n, i) * dot(n, i))
  if k >= 0.0:
    result = eta * i - (eta * dot(n, i) + sqrt(k)) * n
proc refract*(i, n: Vec4; eta: float32): Vec4 =
  # For a given incident vector ``i``, surface normal ``n`` and ratio of indices of refraction, ``eta``, refract returns the refraction vector.
  let k = 1 - eta * eta * (1 - dot(n, i) * dot(n, i))
  if k >= 0.0:
    result = eta * i - (eta * dot(n, i) + sqrt(k)) * n
proc reflect*(a, b: Vec2): Vec2 = a - 2 * dot(a, b) * b
proc reflect*(a, b: Vec3): Vec3 = a - 2 * dot(a, b) * b
proc reflect*(a, b: Vec4): Vec4 = a - 2 * dot(a, b) * b
proc min*(v: Vec2, f: float32): Vec2 = vec2(min(v.x, f), min(v.y, f))
proc min*(v: Vec3, f: float32): Vec3 = vec3(min(v.x, f), min(v.y, f), min(v.z, f))
proc min*(v: Vec4, f: float32): Vec4 = vec4(min(v.x, f), min(v.y, f), min(v.z, f), min(v.w, f))
proc max*(v: Vec2, f: float32): Vec2 = vec2(max(v.x, f), max(v.y, f))
proc max*(v: Vec3, f: float32): Vec3 = vec3(max(v.x, f), max(v.y, f), max(v.z, f))
proc max*(v: Vec4, f: float32): Vec4 = vec4(max(v.x, f), max(v.y, f), max(v.z, f), max(v.w, f))
proc inversesqrt*(x: float32): float32 {.inline, noinit.} = 1 / sqrt(x)
proc inversesqrt*(x: Vec2): Vec2 = vec2(inversesqrt(x.x), inversesqrt(x.y))
proc inversesqrt*(x: Vec3): Vec3 = vec3(inversesqrt(x.x), inversesqrt(x.y), inversesqrt(x.z))
proc inversesqrt*(x: Vec4): Vec4 = vec4(inversesqrt(x.x), inversesqrt(x.y), inversesqrt(x.z), inversesqrt(x.w))
proc atan*(a, b: float32): float32 = arctan2(a, b)
proc acos*(a: float32): float32 = arccos(a)
proc fract*(v: float32): float32 = v - floor(v)
proc fract*(v: Vec2): Vec2 = vec2(fract(v.x), fract(v.y))
proc fract*(v: Vec3): Vec3 = vec3(fract(v.x), fract(v.y), fract(v.z))
proc fract*(v: Vec4): Vec4 = vec4(fract(v.x), fract(v.y), fract(v.z), fract(v.w))
proc log*(a: float32): float32 = log(a, E)
proc pow*(a, b: Vec2): Vec2 = vec2(pow(a.x, b.x), pow(a.y, b.y))
proc pow*(a, b: Vec3): Vec3 = vec3(pow(a.x, b.x), pow(a.y, b.y), pow(a.z, b.z))
proc pow*(a, b: Vec4): Vec4 = vec4(pow(a.x, b.x), pow(a.y, b.y), pow(a.z, b.z), pow(a.w, b.w))
proc sqrt*(a: Vec2): Vec2 = vec2(sqrt(a.x), sqrt(a.y))
proc sqrt*(a: Vec3): Vec3 = vec3(sqrt(a.x), sqrt(a.y), sqrt(a.z))
proc sqrt*(a: Vec4): Vec4 = vec4(sqrt(a.x), sqrt(a.y), sqrt(a.z), sqrt(a.w))
proc abs*(a: Vec2): Vec2 = vec2(abs(a.x), abs(a.y))
proc abs*(a: Vec3): Vec3 = vec3(abs(a.x), abs(a.y), abs(a.z))
proc abs*(a: Vec4): Vec4 = vec4(abs(a.x), abs(a.y), abs(a.z), abs(a.w))
