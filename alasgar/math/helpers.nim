import strformat
import math
import hashes
import random

import vmath

export random, hashes, strformat, math

# Defines epsilon
const EPSILON*: float32 = 0.0000001
const HALF_PI*: float32 = 1.570796326795
const ONE_OVER_PI*: float32 = 0.3183098861837697
const LOG2*: float32 = 1.442695

# Scalar
func inverseLerp*(a, b, v: float32): float32 = (v - a) / (b - a)
func lerp*(a, b, v: float32): float32 = a * (1.0 - v) + b * v
func lerp*(a: Vec3, b: Vec3, v: float32): Vec3 = a * (1.0 - v) + b * v
func map*(x, A, B, C, D: float32): float32 = (x - A) / (B - A) * (D - C) + C

# Vec3
let VEC3_ZERO* = vec3(0, 0, 0)
let VEC3_ONE* = vec3(1, 1, 1)
let VEC3_RIGHT* = vec3(1, 0, 0)
let VEC3_LEFT* = vec3(-1, 0, 0)
let VEC3_UP* = vec3(0, 1, 0)
let VEC3_DOWN* = vec3(0, -1, 0)
let VEC3_FORWARD* = vec3(0, 0, -1)
let VEC3_BACK* = vec3(0, 0, 1)
func `*`*(a: float32, b: Vec3): Vec3 = b * a
func `*=`*(v: var Vec3, f: float) = 
    v.x *= f
    v.y *= f
    v.z *= f
func `/`*(a: float32, b: Vec3): Vec3 = vec3(a / b.x, a / b.y, a / b.z)
func caddr*(v: var Vec3): ptr float32 = v[0].addr
func vec3*(p: ptr float32, offset: int=0): Vec3 =
    let 
        address = cast[ByteAddress](p)
        x = cast[ptr float32](address + offset * sizeof(float32))
        y = cast[ptr float32](address + (offset + 1) * sizeof(float32))
        z = cast[ptr float32](address + (offset + 2) * sizeof(float32))
    result = vec3(x[], y[], z[]) 
func vec3*(v: array[3, float32]): Vec3 = vec3(v[0], v[1], v[2])
func vec3*(v: Vec3): Vec3 = v
func vec3*(v: Vec2): Vec3 = vec3(v.x, v.y, 0.0)
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

# Vec2
func `*`*(a: float32, b: Vec2): Vec2 = b * a
func `/`*(a: float32, b: Vec2): Vec2 = vec2(a / b.x, a / b.y)
func caddr*(v: var Vec2): ptr float32 = v[0].addr
func `iWidth`*(a: Vec2): int32 = a.x.int32
func `iHeight`*(a: Vec2): int32 = a.y.int32
func `width`*(a: Vec2): float32 = a.x
func `height`*(a: Vec2): float32 = a.y
func vec2*(p: ptr float32, offset: int=0): Vec2 =
    let 
        address = cast[ByteAddress](p)
        x = cast[ptr float32](address + offset * sizeof(float32))
        y = cast[ptr float32](address + (offset + 1) * sizeof(float32))
    result = vec2(x[], y[]) 

# Vec4
func vec4*(xy: Vec2, z: float32, w: float32): Vec4 = vec4(xy.x, xy.y, z, w)
func `*`*(a: float32, b: Vec4): Vec4 = b * a
func `/`*(a: float32, b: Vec4): Vec4 = vec4(a / b.x, a / b.y, a / b.z, a / b.w)
func caddr*(v: var Vec4): ptr float32 = v[0].addr

# Mat3
func caddr*(m: var Mat3): ptr float32 = cast[ptr float32](m.addr)

# Mat4
func mat4*(m: array[16, float32]): Mat4 = 
    result[0, 0] = m[0]
    result[0, 1] = m[1]
    result[0, 2] = m[2]
    result[0, 3] = m[3]
    result[1, 0] = m[4]
    result[1, 1] = m[5]
    result[1, 2] = m[6]
    result[1, 3] = m[7]
    result[2, 0] = m[8]
    result[2, 1] = m[9]
    result[2, 2] = m[10]
    result[2, 3] = m[11]
    result[3, 0] = m[12]
    result[3, 1] = m[13]
    result[3, 2] = m[14]
    result[3, 3] = m[15]
func mat4*(m: ptr float32): Mat4 = 
    var p = cast[ptr array[16, float32]](m)
    result = mat4(p[])
func caddr*(m: var Mat4): ptr float32 = cast[ptr float32](m.addr)
func scale*(b: Mat4): Vec3 = 
  let
    b00 = b[0][0]
    b01 = b[0][1]
    b02 = b[0][2]
    b03 = b[0][3]
    b10 = b[1][0]
    b11 = b[1][1]
    b12 = b[1][2]
    b13 = b[1][3]
    b20 = b[2][0]
    b21 = b[2][1]
    b22 = b[2][2]
    b23 = b[2][3]
    xs: float32 = sign(b00 * b01 * b02 * b03)
    ys: float32 = sign(b10 * b11 * b12 * b13)
    zs: float32 = sign(b20 * b21 * b22 * b23)

  result.x = xs * sqrt(b00 * b00 + b01 * b01 + b02 * b02)
  result.y = ys * sqrt(b10 * b10 + b11 * b11 + b12 * b12)
  result.z = zs * sqrt(b20 * b20 + b21 * b21 + b22 * b22)

func identity*(): Mat4 =
  result[0, 0] = 1
  result[1, 1] = 1
  result[2, 2] = 1
  result[3, 3] = 1 

# Quat
func quat*(p: ptr float32, offset: int=0): Quat =
    let 
        address = cast[ByteAddress](p)
        x = cast[ptr float32](address + offset * sizeof(float32))
        y = cast[ptr float32](address + (offset + 1) * sizeof(float32))
        z = cast[ptr float32](address + (offset + 2) * sizeof(float32))
        w = cast[ptr float32](address + (offset + 3) * sizeof(float32))
    result = quat(x[], y[], z[], w[]) 

func `*`*(q, p: Quat): Quat =
    result.x =   p.x * q.w  + p.y * q.z - p.z * q.y + p.w * q.x
    result.y = -(p.x * q.z) + p.y * q.w + p.z * q.x + p.w * q.y
    result.z =   p.x * q.y  - p.y * q.x + p.z * q.w + p.w * q.z
    result.w = -(p.x * q.x) - p.y * q.y - p.z * q.z + p.w * q.w  

func `*`*(q: Quat, v: Vec3): Vec3 =
    var
        x = v.x
        y = v.y
        z = v.z
        qx = q.x
        qy = q.y
        qz = q.z
        qw = q.w
        ix = +qw * x + qy * z - qz * y
        iy = +qw * y + qz * x - qx * z
        iz = +qw * z + qx * y - qy * x
        iw = -qx * x - qy * y - qz * z

    result.x = ix * qw + iw * -qx + iy * -qz - iz * -qy
    result.y = iy * qw + iw * -qy + iz * -qx - ix * -qz
    result.z = iz * qw + iw * -qz + ix * -qy - iy * -qx

func fromEuler*(yaw, pitch, roll: float32): Quat =
    let cy = cos(yaw * 0.5)
    let sy = sin(yaw * 0.5)
    let cp = cos(pitch * 0.5)
    let sp = sin(pitch * 0.5)
    let cr = cos(roll * 0.5)
    let sr = sin(roll * 0.5)

    result.w = cr * cp * cy + sr * sp * sy
    result.x = sr * cp * cy - cr * sp * sy
    result.y = cr * sp * cy + sr * cp * sy
    result.z = cr * cp * sy - sr * sp * cy

func fromEuler*(v: Vec3): Quat =
    let yaw = v.x
    let pitch = v.y
    let roll = v.z
    let cy = cos(yaw * 0.5)
    let sy = sin(yaw * 0.5)
    let cp = cos(pitch * 0.5)
    let sp = sin(pitch * 0.5)
    let cr = cos(roll * 0.5)
    let sr = sin(roll * 0.5)

    result.w = cr * cp * cy + sr * sp * sy
    result.x = sr * cp * cy - cr * sp * sy
    result.y = cr * sp * cy + sr * cp * sy
    result.z = cr * cp * sy - sr * sp * cy

func conjugate*(quat: Quat): Quat =
    result.x = quat.x * -1.0
    result.y = quat.y * -1.0
    result.z = quat.z * -1.0
    result.w = quat.w

func inverse*(quat: Quat): Quat =
    var norm = quat.x * quat.x + quat.y * quat.y + quat.z * quat.z + quat.w * quat.w
    var recip = -1.0 / norm;
    result.x = quat.x * recip
    result.y = quat.y * recip
    result.z = quat.z * recip
    result.w = quat.w * -recip   

func fromToRotation*(a, b: Vec3): Quat =
    var p0 = normalize(a)
    var p1 = normalize(b)

    if p0 == -p1:
        var mostOrthogonal = vec3(1, 0, 0)

        if abs(p0.y) < abs(p0.x):
            mostOrthogonal = vec3(0, 1, 0);

        if abs(p0.z) < abs(p0.y) and abs(p0.z) < abs(p0.x):
            mostOrthogonal = vec3(0, 0, 1)

        var axis = normalize(cross(p0, mostOrthogonal))
        result = quat(axis.x, axis.y, axis.z, 0)
    else:
        var half = normalize(p0 + p1)
        var axis = cross(p0, half)

        result.x = axis.x
        result.y = axis.y
        result.z = axis.z
        result.w = dot(p0, half)
    
func `*`*(v: Vec3, q: Quat): Vec3 =
    var u = vec3(q.x, q.y, q.z)
    var s = q.w
    result = (2 * dot(u, v) * u) + ((s * s - dot(u, u)) * v) + (2 * s * cross(u, v))

func lookAt*(direction: Vec3, up: Vec3=VEC3_UP): Quat =
    # Normalize input data
    var dir = normalize(direction)
    var desiredUp = normalize(up)

    # Step 1, Find quaternion that rotates from forward to direction
    var fromForwardToDirection = fromToRotation(vec3(0, 0, 1), dir)

    # Step 2, Make sure up is perpendicular to desired direction
    var right = cross(dir, desiredUp)
    desiredUp = cross(right, dir)

    # Step 3, Find the up vector of the quaternion from Step 1
    # Quaternion-vector multiplication (will be covered later)
    var objectUp = vec3(0, 1, 0) * fromForwardToDirection
    
    # Step 4, Create quaternion from object up to desired up
    var fromObjectUpToDesiredUp = fromToRotation(objectUp, desiredUp)

    # Step 5, Combine rotations (in reverse! forward applied first, then up)
    # Quaternion-quaternion multiplication (will be covered later)
    var q = fromForwardToDirection * fromObjectUpToDesiredUp

    # Should not be needed, but normalize output data
    result = normalize(q)

func step*(edge, x: float32): float32 =
    if x < edge:
        0.0
    else:
        1.0

func smoothstep*(edge0, edge1, x: float32): float32 =
    if x < edge0:
        result = 0.0
    elif x > edge1:
        result = 1.0
    else:
        var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
        result = t * t * (3.0 - 2.0 * t)