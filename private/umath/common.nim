import math

type
  Color* = uint32
  GVec2*[T] = object
    x*, y*: T
  GVec3*[T] = object
    x*, y*, z*: T
  GVec4*[T] = object
    x*, y*, z*, w*: T
  Vec2* = GVec2[float32]
  IVec2* = GVec2[int32]
  UVec2* = GVec2[uint32]
  Vec3* = GVec3[float32]
  IVec3* = GVec3[int32]
  UVec3* = GVec3[uint32]
  Vec4* = GVec4[float32]
  IVec4* = GVec4[int32]
  UVec4* = GVec4[uint32]
  Quat* = Vec4
  Mat3* = tuple
    m00: float32
    m01: float32
    m02: float32
    m10: float32
    m11: float32
    m12: float32
    m20: float32
    m21: float32
    m22: float32
  Mat4* = tuple
    m00: float32
    m01: float32
    m02: float32
    m03: float32
    m10: float32
    m11: float32
    m12: float32
    m13: float32
    m20: float32
    m21: float32
    m22: float32
    m23: float32
    m30: float32
    m31: float32
    m32: float32
    m33: float32

const
  EPSILON*: float32 = 0.0000001
  HALF_PI*: float32 = 1.5707963
  ONE_OVER_PI*: float32 = 0.3183098
  LOG2*: float32 = 1.442695

template caddr*[T](v: GVec2[T] | GVec3[T] | GVec4[T]): ptr T = v.x.addr
template caddr*(m: Mat3 | Mat4): ptr float32 = addr m.m00
template caddr*(m: ptr Mat3 | ptr Mat4): ptr float32 = addr m.m00
func `r`*(v: Vec4|Vec3): float32 = v.x
func `g`*(v: Vec4|Vec3): float32 = v.y
func `b`*(v: Vec4|Vec3): float32 = v.z
func `a`*(v: Vec4): float32 = v.w
func `rgb`*(v: Vec4|Vec3): Vec3 = Vec3(x: v.x, y: v.y, z: v.z)
func `rgba`*(v: Vec4): Vec4 = Vec4(x: v.x, y: v.y, z: v.z, w: v.w)
func `rgba`*(v: Vec3): Vec4 = Vec4(x: v.x, y: v.y, z: v.z, w: 1.0)
