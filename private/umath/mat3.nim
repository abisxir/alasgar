import common


func mat3*(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9: float32): Mat3 = (
  v0, v1, v2,
  v3, v4, v5,
  v6, v7, v8,
)

func mat3*(v1, v2, v3: Vec3): Mat3 = (
  v1.x, v1.y, v1.z,
  v2.x, v2.y, v2.z,
  v3.x, v3.y, v3.z,
)

func mat3*(v: float32): Mat3 = (
  v, v, v,
  v, v, v,
  v, v, v,
)

func mat3*(): Mat3 = (
  1, 0, 0,
  0, 1, 0,
  0, 0, 1,
)

func `*`*(f: float32, m: Mat3): Mat3 = (
  m[0] * f, m[1] * f, m[2] * f,
  m[3] * f, m[4] * f, m[5] * f,
  m[6] * f, m[7] * f, m[8] * f,
)

func `*`*(m: Mat3, f: float32): Mat3 = f * m

func `*`*(m: Mat3, v: Vec3): Vec3 = Vec3(
  x: m.m00 * v.x + m.m01 * v.y + m.m02 * v.z,
  y: m.m10 * v.x + m.m11 * v.y + m.m12 * v.z,
  z: m.m20 * v.x + m.m21 * v.y + m.m22 * v.z
)
