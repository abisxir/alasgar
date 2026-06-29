import math

import common, vec2, vec3, vec4

func radians*(degrees: float32): float32 = degrees * PI / 180.0
func radians*(degrees: Vec2): Vec2 = vec2(radians(degrees.x), radians(degrees.y))
func radians*(degrees: Vec3): Vec3 = vec3(radians(degrees.x), radians(degrees.y), radians(degrees.z))
func radians*(degrees: Vec4): Vec4 = vec4(radians(degrees.x), radians(degrees.y), radians(degrees.z), radians(degrees.w))

func degrees*(radians: float32): float32 = radians * 180.0 / PI
func degrees*(radians: Vec2): Vec2 = vec2(degrees(radians.x), degrees(radians.y))
func degrees*(radians: Vec3): Vec3 = vec3(degrees(radians.x), degrees(radians.y), degrees(radians.z))
func degrees*(radians: Vec4): Vec4 = vec4(degrees(radians.x), degrees(radians.y), degrees(radians.z), degrees(radians.w))

func sin*(x: Vec2): Vec2 = vec2(sin(x.x), sin(x.y))
func sin*(x: Vec3): Vec3 = vec3(sin(x.x), sin(x.y), sin(x.z))
func sin*(x: Vec4): Vec4 = vec4(sin(x.x), sin(x.y), sin(x.z), sin(x.w))

func cos*(x: Vec2): Vec2 = vec2(cos(x.x), cos(x.y))
func cos*(x: Vec3): Vec3 = vec3(cos(x.x), cos(x.y), cos(x.z))
func cos*(x: Vec4): Vec4 = vec4(cos(x.x), cos(x.y), cos(x.z), cos(x.w))

func tan*(x: Vec2): Vec2 = vec2(tan(x.x), tan(x.y))
func tan*(x: Vec3): Vec3 = vec3(tan(x.x), tan(x.y), tan(x.z))
func tan*(x: Vec4): Vec4 = vec4(tan(x.x), tan(x.y), tan(x.z), tan(x.w))

func asin*(x: Vec2): Vec2 = vec2(arcsin(x.x), arcsin(x.y))
func asin*(x: Vec3): Vec3 = vec3(arcsin(x.x), arcsin(x.y), arcsin(x.z))
func asin*(x: Vec4): Vec4 = vec4(arcsin(x.x), arcsin(x.y), arcsin(x.z), arcsin(x.w))

func acos*(x: Vec2): Vec2 = vec2(arccos(x.x), arccos(x.y))
func acos*(x: Vec3): Vec3 = vec3(arccos(x.x), arccos(x.y), arccos(x.z))
func acos*(x: Vec4): Vec4 = vec4(arccos(x.x), arccos(x.y), arccos(x.z), arccos(x.w))

func atan*(y, x: float32): float32 = arctan2(y, x)
func atan*(y, x: Vec2): Vec2 = vec2(atan(y.x, x.x), atan(y.y, x.y))
func atan*(y, x: Vec3): Vec3 = vec3(atan(y.x, x.x), atan(y.y, x.y), atan(y.z, x.z))
func atan*(y, x: Vec4): Vec4 = vec4(atan(y.x, x.x), atan(y.y, x.y), atan(y.z, x.z), atan(y.w, x.w))
func atan*(x: Vec2): Vec2 = vec2(arctan(x.x), arctan(x.y))
func atan*(x: Vec3): Vec3 = vec3(arctan(x.x), arctan(x.y), arctan(x.z))
func atan*(x: Vec4): Vec4 = vec4(arctan(x.x), arctan(x.y), arctan(x.z), arctan(x.w))

func pow*(x, y: Vec2): Vec2 = vec2(pow(x.x, y.x), pow(x.y, y.y))
func pow*(x, y: Vec3): Vec3 = vec3(pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z))
func pow*(x, y: Vec4): Vec4 = vec4(pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z), pow(x.w, y.w))

func exp*(x: Vec2): Vec2 = vec2(exp(x.x), exp(x.y))
func exp*(x: Vec3): Vec3 = vec3(exp(x.x), exp(x.y), exp(x.z))
func exp*(x: Vec4): Vec4 = vec4(exp(x.x), exp(x.y), exp(x.z), exp(x.w))

func exp2*(x: float32): float32 = pow(2.0'f32, x)
func exp2*(x: Vec2): Vec2 = vec2(exp2(x.x), exp2(x.y))
func exp2*(x: Vec3): Vec3 = vec3(exp2(x.x), exp2(x.y), exp2(x.z))
func exp2*(x: Vec4): Vec4 = vec4(exp2(x.x), exp2(x.y), exp2(x.z), exp2(x.w))

func log*(x: Vec2): Vec2 = vec2(ln(x.x), ln(x.y))
func log*(x: Vec3): Vec3 = vec3(ln(x.x), ln(x.y), ln(x.z))
func log*(x: Vec4): Vec4 = vec4(ln(x.x), ln(x.y), ln(x.z), ln(x.w))

func log2*(x: float32): float32 = ln(x) * LOG2
func log2*(x: Vec2): Vec2 = vec2(log2(x.x), log2(x.y))
func log2*(x: Vec3): Vec3 = vec3(log2(x.x), log2(x.y), log2(x.z))
func log2*(x: Vec4): Vec4 = vec4(log2(x.x), log2(x.y), log2(x.z), log2(x.w))

func sqrt*(x: Vec2): Vec2 = vec2(sqrt(x.x), sqrt(x.y))
func sqrt*(x: Vec3): Vec3 = vec3(sqrt(x.x), sqrt(x.y), sqrt(x.z))
func sqrt*(x: Vec4): Vec4 = vec4(sqrt(x.x), sqrt(x.y), sqrt(x.z), sqrt(x.w))

func inversesqrt*(x: float32): float32 = 1.0'f32 / sqrt(x)
func inversesqrt*(x: Vec2): Vec2 = vec2(inversesqrt(x.x), inversesqrt(x.y))
func inversesqrt*(x: Vec3): Vec3 = vec3(inversesqrt(x.x), inversesqrt(x.y), inversesqrt(x.z))
func inversesqrt*(x: Vec4): Vec4 = vec4(inversesqrt(x.x), inversesqrt(x.y), inversesqrt(x.z), inversesqrt(x.w))

func abs*(x: Vec2): Vec2 = vec2(abs(x.x), abs(x.y))
func abs*(x: Vec3): Vec3 = vec3(abs(x.x), abs(x.y), abs(x.z))
func abs*(x: Vec4): Vec4 = vec4(abs(x.x), abs(x.y), abs(x.z), abs(x.w))

func fract*(x: float32): float32 = x - floor(x)
func fract*(x: Vec2): Vec2 = x - floor(x)
func fract*(x: Vec3): Vec3 = x - floor(x)
func fract*(x: Vec4): Vec4 = x - floor(x)

func `mod`*(x, y: float32): float32 = x - y * floor(x / y)
func `mod`*(x, y: Vec2): Vec2 = x - y * floor(x / y)
func `mod`*(x, y: Vec3): Vec3 = x - y * floor(x / y)
func `mod`*(x, y: Vec4): Vec4 = x - y * floor(x / y)
func `mod`*(x: Vec2, y: float32): Vec2 = x - y * floor(x / y)
func `mod`*(x: Vec3, y: float32): Vec3 = x - y * floor(x / y)
func `mod`*(x: Vec4, y: float32): Vec4 = x - y * floor(x / y)

func clamp01*(x: float32): float32 = clamp(x, 0.0'f32, 1.0'f32)
func clamp01*(x: Vec2): Vec2 = clamp(x, vec2(0), vec2(1))
func clamp01*(x: Vec3): Vec3 = clamp(x, vec3(0), vec3(1))
func clamp01*(x: Vec4): Vec4 = clamp(x, vec4(0), vec4(1))

func mix*(x, y, a: float32): float32 = x * (1.0'f32 - a) + y * a
func mix*(x, y, a: Vec2): Vec2 = x * (vec2(1) - a) + y * a
func mix*(x, y, a: Vec3): Vec3 = x * (vec3(1) - a) + y * a
func mix*(x, y, a: Vec4): Vec4 = x * (vec4(1) - a) + y * a
func mix*(x, y: Vec2, a: float32): Vec2 = x * (1.0'f32 - a) + y * a
func mix*(x, y: Vec3, a: float32): Vec3 = x * (1.0'f32 - a) + y * a
func mix*(x, y: Vec4, a: float32): Vec4 = x * (1.0'f32 - a) + y * a

func step*(edge, x: float32): float32 =
  if x < edge: 0.0'f32 else: 1.0'f32
func step*(edge, x: Vec2): Vec2 = vec2(step(edge.x, x.x), step(edge.y, x.y))
func step*(edge, x: Vec3): Vec3 = vec3(step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z))
func step*(edge, x: Vec4): Vec4 = vec4(step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z), step(edge.w, x.w))
func step*(edge: float32, x: Vec2): Vec2 = vec2(step(edge, x.x), step(edge, x.y))
func step*(edge: float32, x: Vec3): Vec3 = vec3(step(edge, x.x), step(edge, x.y), step(edge, x.z))
func step*(edge: float32, x: Vec4): Vec4 = vec4(step(edge, x.x), step(edge, x.y), step(edge, x.z), step(edge, x.w))

func smoothstep*(edge0, edge1, x: float32): float32 =
  let t = clamp01((x - edge0) / (edge1 - edge0))
  t * t * (3.0'f32 - 2.0'f32 * t)
func smoothstep*(edge0, edge1, x: Vec2): Vec2 =
  let t = clamp01((x - edge0) / (edge1 - edge0))
  t * t * (vec2(3) - 2.0'f32 * t)
func smoothstep*(edge0, edge1, x: Vec3): Vec3 =
  let t = clamp01((x - edge0) / (edge1 - edge0))
  t * t * (vec3(3) - 2.0'f32 * t)
func smoothstep*(edge0, edge1, x: Vec4): Vec4 =
  let t = clamp01((x - edge0) / (edge1 - edge0))
  t * t * (vec4(3) - 2.0'f32 * t)
func smoothstep*(edge0, edge1: float32, x: Vec2): Vec2 = smoothstep(vec2(edge0), vec2(edge1), x)
func smoothstep*(edge0, edge1: float32, x: Vec3): Vec3 = smoothstep(vec3(edge0), vec3(edge1), x)
func smoothstep*(edge0, edge1: float32, x: Vec4): Vec4 = smoothstep(vec4(edge0), vec4(edge1), x)

func reflect*(i, n: Vec2): Vec2 = i - 2.0'f32 * dot(n, i) * n
func reflect*(i, n: Vec3): Vec3 = i - 2.0'f32 * dot(n, i) * n
func reflect*(i, n: Vec4): Vec4 = i - 2.0'f32 * dot(n, i) * n

func refract*(i, n: Vec2, eta: float32): Vec2 =
  let k = 1.0'f32 - eta * eta * (1.0'f32 - dot(n, i) * dot(n, i))
  if k < 0.0'f32: vec2(0) else: eta * i - (eta * dot(n, i) + sqrt(k)) * n
func refract*(i, n: Vec3, eta: float32): Vec3 =
  let k = 1.0'f32 - eta * eta * (1.0'f32 - dot(n, i) * dot(n, i))
  if k < 0.0'f32: vec3(0) else: eta * i - (eta * dot(n, i) + sqrt(k)) * n
func refract*(i, n: Vec4, eta: float32): Vec4 =
  let k = 1.0'f32 - eta * eta * (1.0'f32 - dot(n, i) * dot(n, i))
  if k < 0.0'f32: vec4(0) else: eta * i - (eta * dot(n, i) + sqrt(k)) * n

func faceforward*(n, i, nref: Vec2): Vec2 =
  if dot(nref, i) < 0.0'f32: n else: 0.0'f32 - n
func faceforward*(n, i, nref: Vec3): Vec3 =
  if dot(nref, i) < 0.0'f32: n else: 0.0'f32 - n
func faceforward*(n, i, nref: Vec4): Vec4 =
  if dot(nref, i) < 0.0'f32: n else: 0.0'f32 - n

func dFdx*(x: float32): float32 = 0.0'f32
func dFdx*(x: Vec2): Vec2 = vec2(0)
func dFdx*(x: Vec3): Vec3 = vec3(0)
func dFdx*(x: Vec4): Vec4 = vec4(0)

func dFdy*(x: float32): float32 = 0.0'f32
func dFdy*(x: Vec2): Vec2 = vec2(0)
func dFdy*(x: Vec3): Vec3 = vec3(0)
func dFdy*(x: Vec4): Vec4 = vec4(0)

func fwidth*(x: float32): float32 = abs(dFdx(x)) + abs(dFdy(x))
func fwidth*(x: Vec2): Vec2 = abs(dFdx(x)) + abs(dFdy(x))
func fwidth*(x: Vec3): Vec3 = abs(dFdx(x)) + abs(dFdy(x))
func fwidth*(x: Vec4): Vec4 = abs(dFdx(x)) + abs(dFdy(x))
