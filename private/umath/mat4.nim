import math
import common, vec3, vec4

## 4x4 Matrix - OpenGL row order
func mat4*(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15: float32): Mat4 = (
  v0, v1, v2, v3,
  v4, v5, v6, v7,
  v8, v9, v10, v11,
  v12, v13, v14, v15,
)

func mat4*(a: Mat4): Mat4 = a

func mat4*(p: ptr float32): Mat4 =
  var pm = cast[ptr Mat4](p)
  result = pm[]

func mat4*(m: array[16, float32]): Mat4 = (
  m[0], m[1], m[2], m[3],
  m[4], m[5], m[6], m[7],
  m[8], m[9], m[10], m[11],
  m[12], m[13], m[14], m[15],
)

func mat4*(): Mat4 = (
  1, 0, 0, 0,
  0, 1, 0, 0,
  0, 0, 1, 0,
  0, 0, 0, 1,
)

func mat4*(e: float32): Mat4 = (
  e, e, e, e,
  e, e, e, e,
  e, e, e, e,
  e, e, e, e,
)

func transpose*(a: Mat4): Mat4 = (
  a[0], a[4], a[8], a[12],
  a[1], a[5], a[9], a[13],
  a[2], a[6], a[10], a[14],
  a[3], a[7], a[11], a[15],
)

func mat4*(v0, v1, v2, v3: Vec4): Mat4 = (
  v0.x, v0.y, v0.z, v0.w,
  v1.x, v1.y, v1.z, v1.w,
  v2.x, v2.y, v2.z, v2.w,
  v3.x, v3.y, v3.z, v3.w,
)

func determinant*(a: Mat4): float32 =
  var
    a00 = a[0]
    a01 = a[1]
    a02 = a[2]
    a03 = a[3]
    a10 = a[4]
    a11 = a[5]
    a12 = a[6]
    a13 = a[7]
    a20 = a[8]
    a21 = a[9]
    a22 = a[10]
    a23 = a[11]
    a30 = a[12]
    a31 = a[13]
    a32 = a[14]
    a33 = a[15]

  (
    a30*a21*a12*a03 - a20*a31*a12*a03 - a30*a11*a22*a03 + a10*a31*a22*a03 +
    a20*a11*a32*a03 - a10*a21*a32*a03 - a30*a21*a02*a13 + a20*a31*a02*a13 +
    a30*a01*a22*a13 - a00*a31*a22*a13 - a20*a01*a32*a13 + a00*a21*a32*a13 +
    a30*a11*a02*a23 - a10*a31*a02*a23 - a30*a01*a12*a23 + a00*a31*a12*a23 +
    a10*a01*a32*a23 - a00*a11*a32*a23 - a20*a11*a02*a33 + a10*a21*a02*a33 +
    a20*a01*a12*a33 - a00*a21*a12*a33 - a10*a01*a22*a33 + a00*a11*a22*a33
  )

func inverse*(a: Mat4): Mat4 =
  var
    b00 = a.m00*a.m11 - a.m01*a.m10
    b01 = a.m00*a.m12 - a.m02*a.m10
    b02 = a.m00*a.m13 - a.m03*a.m10
    b03 = a.m01*a.m12 - a.m02*a.m11
    b04 = a.m01*a.m13 - a.m03*a.m11
    b05 = a.m02*a.m13 - a.m03*a.m12
    b06 = a.m20*a.m31 - a.m21*a.m30
    b07 = a.m20*a.m32 - a.m22*a.m30
    b08 = a.m20*a.m33 - a.m23*a.m30
    b09 = a.m21*a.m32 - a.m22*a.m31
    b10 = a.m21*a.m33 - a.m23*a.m31
    b11 = a.m22*a.m33 - a.m23*a.m32

  # Calculate the invese determinant
  var invDet = 1.0/(b00*b11 - b01*b10 + b02*b09 + b03*b08 - b04*b07 + b05*b06)

  (
    (+a.m11*b11 - a.m12*b10 + a.m13*b09)*invDet,
    (-a.m01*b11 + a.m02*b10 - a.m03*b09)*invDet,
    (+a.m31*b05 - a.m32*b04 + a.m33*b03)*invDet,
    (-a.m21*b05 + a.m22*b04 - a.m23*b03)*invDet,
    (-a.m10*b11 + a.m12*b08 - a.m13*b07)*invDet,
    (+a.m00*b11 - a.m02*b08 + a.m03*b07)*invDet,
    (-a.m30*b05 + a.m32*b02 - a.m33*b01)*invDet,
    (+a.m20*b05 - a.m22*b02 + a.m23*b01)*invDet,
    (+a.m10*b10 - a.m11*b08 + a.m13*b06)*invDet,
    (-a.m00*b10 + a.m01*b08 - a.m03*b06)*invDet,
    (+a.m30*b04 - a.m31*b02 + a.m33*b00)*invDet,
    (-a.m20*b04 + a.m21*b02 - a.m23*b00)*invDet,
    (-a.m10*b09 + a.m11*b07 - a.m12*b06)*invDet,
    (+a.m00*b09 - a.m01*b07 + a.m02*b06)*invDet,
    (-a.m30*b03 + a.m31*b01 - a.m32*b00)*invDet,
    (+a.m20*b03 - a.m21*b01 + a.m22*b00)*invDet
  )

func `*`*(a, b: Mat4): Mat4 = (
  b.m00*a.m00 + b.m01*a.m10 + b.m02*a.m20 + b.m03*a.m30,
  b.m00*a.m01 + b.m01*a.m11 + b.m02*a.m21 + b.m03*a.m31,
  b.m00*a.m02 + b.m01*a.m12 + b.m02*a.m22 + b.m03*a.m32,
  b.m00*a.m03 + b.m01*a.m13 + b.m02*a.m23 + b.m03*a.m33,
  b.m10*a.m00 + b.m11*a.m10 + b.m12*a.m20 + b.m13*a.m30,
  b.m10*a.m01 + b.m11*a.m11 + b.m12*a.m21 + b.m13*a.m31,
  b.m10*a.m02 + b.m11*a.m12 + b.m12*a.m22 + b.m13*a.m32,
  b.m10*a.m03 + b.m11*a.m13 + b.m12*a.m23 + b.m13*a.m33,
  b.m20*a.m00 + b.m21*a.m10 + b.m22*a.m20 + b.m23*a.m30,
  b.m20*a.m01 + b.m21*a.m11 + b.m22*a.m21 + b.m23*a.m31,
  b.m20*a.m02 + b.m21*a.m12 + b.m22*a.m22 + b.m23*a.m32,
  b.m20*a.m03 + b.m21*a.m13 + b.m22*a.m23 + b.m23*a.m33,
  b.m30*a.m00 + b.m31*a.m10 + b.m32*a.m20 + b.m33*a.m30,
  b.m30*a.m01 + b.m31*a.m11 + b.m32*a.m21 + b.m33*a.m31,
  b.m30*a.m02 + b.m31*a.m12 + b.m32*a.m22 + b.m33*a.m32,
  b.m30*a.m03 + b.m31*a.m13 + b.m32*a.m23 + b.m33*a.m33,
)


func `+`*(a, b: Mat4): Mat4 = (
  a[0] + b[0], a[1] + b[1], a[2] + b[2], a[3] + b[3],
  a[4] + b[4], a[5] + b[5], a[6] + b[6], a[7] + b[7],
  a[8] + b[8], a[9] + b[9], a[10] + b[10], a[11] + b[11],
  a[12] + b[12], a[13] + b[13], a[14] + b[14], a[15] + b[15]
)

func `*`*(f: float32, m: Mat4): Mat4 = (
  m[0] * f, m[1] * f, m[2] * f, m[3] * f,
  m[4] * f, m[5] * f, m[6] * f, m[7] * f,
  m[8] * f, m[9] * f, m[10] * f, m[11] * f,
  m[12] * f, m[13] * f, m[14] * f, m[15] * f,
)

func `*`*(m: Mat4, f: float32): Mat4 = f * m

func `*`*(a: Mat4, b: Vec3): Vec3 =
  result.x = a[0]*b.x + a[4]*b.y + a[8]*b.z + a[12]
  result.y = a[1]*b.x + a[5]*b.y + a[9]*b.z + a[13]
  result.z = a[2]*b.x + a[6]*b.y + a[10]*b.z + a[14]

func `*`*(a: Mat4, b: Vec4): Vec4 =
  result.x = a[0]*b.x + a[4]*b.y + a[8]*b.z + a[12]*b.w
  result.y = a[1]*b.x + a[5]*b.y + a[9]*b.z + a[13]*b.w
  result.z = a[2]*b.x + a[6]*b.y + a[10]*b.z + a[14]*b.w
  result.w = a[3]*b.x + a[7]*b.y + a[11]*b.z + a[15]*b.w

func right*(a: Mat4): Vec3 =
  result.x = a[0]
  result.y = a[1]
  result.z = a[2]

func `right=`*(a: var Mat4, b: Vec3) =
  a[0] = b.x
  a[1] = b.y
  a[2] = b.z

func up*(a: Mat4): Vec3 =
  result.x = a[4]
  result.y = a[5]
  result.z = a[6]

func `up=`*(a: var Mat4, b: Vec3) =
  a[4] = b.x
  a[5] = b.y
  a[6] = b.z

func forward*(a: Mat4): Vec3 =
  result.x = a[8]
  result.y = a[9]
  result.z = a[10]

func `forward=`*(a: var Mat4, b: Vec3) =
  a[8] = b.x
  a[9] = b.y
  a[10] = b.z

func pos*(a: Mat4): Vec3 =
  result.x = a[12]
  result.y = a[13]
  result.z = a[14]

func `pos=`*(a: var Mat4, b: Vec3) =
  a[12] = b.x
  a[13] = b.y
  a[14] = b.z

func rotationOnly*(a: Mat4): Mat4 =
  result = a
  result.pos = vec3(0, 0, 0)

func dist*(a, b: Mat4): float32 =
  var
    x = a[12] - b[12]
    y = a[13] - b[13]
    z = a[14] - b[14]
  sqrt(x*x + y*y + z*z)

func translate*(v: Vec3): Mat4 =
  result[0] = 1
  result[5] = 1
  result[10] = 1
  result[15] = 1
  result[12] = v.x
  result[13] = v.y
  result[14] = v.z

func scale*(v: Vec3): Mat4 =
  result[0] = v.x
  result[5] = v.y
  result[10] = v.z
  result[15] = 1

func close*(a: Mat4, b: Mat4): bool =
  (abs(a[0] - b[0]) > 0.001 or
    abs(a[1] - b[1]) > 0.001 or
    abs(a[2] - b[2]) > 0.001 or
    abs(a[3] - b[3]) > 0.001 or
    abs(a[4] - b[4]) > 0.001 or
    abs(a[5] - b[5]) > 0.001 or
    abs(a[6] - b[6]) > 0.001 or
    abs(a[7] - b[7]) > 0.001 or
    abs(a[8] - b[8]) > 0.001 or
    abs(a[9] - b[9]) > 0.001 or
    abs(a[10] - b[10]) > 0.001 or
    abs(a[11] - b[11]) > 0.001 or
    abs(a[12] - b[12]) > 0.001 or
    abs(a[13] - b[13]) > 0.001 or
    abs(a[14] - b[14]) > 0.001 or
    abs(a[15] - b[15]) > 0.001)

func hrp*(m: Mat4): Vec3 =
  var heading, pitch, roll: float32
  if m[1] > 0.998: # singularity at north pole
    heading = arctan2(m[2], m[10])
    pitch = PI / 2
    roll = 0
  elif m[1] < -0.998: # singularity at south pole
    heading = arctan2(m[2], m[10])
    pitch = -PI / 2
    roll = 0
  else:
    heading = arctan2(-m[8], m[0])
    pitch = arctan2(-m[6], m[5])
    roll = arcsin(m[4])
  result.x = heading
  result.y = pitch
  result.z = roll

func frustum*(left, right, bottom, top, near, far: float32): Mat4 =
  var
    rl = (right - left)
    tb = (top - bottom)
    fn = (far - near)
  (
    (near*2) / rl, 0, 0, 0,
    0, (near*2) / tb, 0, 0,
    (right + left) / rl, (top + bottom) / tb, -(far + near) / fn, -1,
    0, 0, -(far*near*2) / fn, 0
  )

func perspective*(fovy, aspect, near, far: float32): Mat4 =
  var
    top = near * tan(fovy*PI / 360.0)
    right = top * aspect
  frustum(-right, right, -top, top, near, far)

func ortho*(left, right, bottom, top, near, far: float32): Mat4 =
  var
    rl = (right - left)
    tb = (top - bottom)
    fn = (far - near)
  (
    2 / rl, 0, 0, 0,
    0, 2 / tb, 0, 0,
    0, 0, -2 / fn, 0,
    -(left + right) / rl, -(top + bottom) / tb, -(far + near) / fn, 1
  )

func psgn[T](x: T): T =
  if sgn(x) < 0:
    result = -1
  else:
    result = 1

func scale*(b: Mat4): Vec3 =
  let
    b00 = b[0]
    b01 = b[1]
    b02 = b[2]
    b03 = b[3]
    b10 = b[4]
    b11 = b[5]
    b12 = b[6]
    b13 = b[7]
    b20 = b[8]
    b21 = b[9]
    b22 = b[10]
    b23 = b[11]
    xs: float32 = psgn(b00 * b01 * b02 * b03)
    ys: float32 = psgn(b10 * b11 * b12 * b13)
    zs: float32 = psgn(b20 * b21 * b22 * b23)

  Vec3(
    x: xs * sqrt(b00 * b00 + b01 * b01 + b02 * b02),
    y: ys * sqrt(b10 * b10 + b11 * b11 + b12 * b12),
    z: zs * sqrt(b20 * b20 + b21 * b21 + b22 * b22),
  )
