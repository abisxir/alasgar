import helpers
import types
import vec3
import vec4

type Mat4* = array[16, float32] ## 4x4 Matrix - OpenGL row order

func mat4*(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13,
    v14, v15: float32): Mat4 =
  result[0] = v0
  result[1] = v1
  result[2] = v2
  result[3] = v3
  result[4] = v4
  result[5] = v5
  result[6] = v6
  result[7] = v7
  result[8] = v8
  result[9] = v9
  result[10] = v10
  result[11] = v11
  result[12] = v12
  result[13] = v13
  result[14] = v14
  result[15] = v15

func mat4*(a: Mat4): Mat4 = a

func mat4*(p: ptr float32): Mat4 =
  var pm = cast[ptr Mat4](p)
  result = pm[]

func identity*(): Mat4 =
  result[0] = 1
  result[1] = 0
  result[2] = 0
  result[3] = 0
  result[4] = 0
  result[5] = 1
  result[6] = 0
  result[7] = 0
  result[8] = 0
  result[9] = 0
  result[10] = 1
  result[11] = 0
  result[12] = 0
  result[13] = 0
  result[14] = 0
  result[15] = 1

func mat4*(e: float32): Mat4 =
  result[0] = e
  result[1] = e
  result[2] = e
  result[3] = e
  result[4] = e
  result[5] = e
  result[6] = e
  result[7] = e
  result[8] = e
  result[9] = e
  result[10] = e
  result[11] = e
  result[12] = e
  result[13] = e
  result[14] = e
  result[15] = e

func mat4*(): Mat4 =
  identity()

func transpose*(a: Mat4): Mat4 =
  result[0] = a[0]
  result[1] = a[4]
  result[2] = a[8]
  result[3] = a[12]

  result[4] = a[1]
  result[5] = a[5]
  result[6] = a[9]
  result[7] = a[13]

  result[8] = a[2]
  result[9] = a[6]
  result[10] = a[10]
  result[11] = a[14]

  result[12] = a[3]
  result[13] = a[7]
  result[14] = a[11]
  result[15] = a[15]

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

  var
    b00 = a00*a11 - a01*a10
    b01 = a00*a12 - a02*a10
    b02 = a00*a13 - a03*a10
    b03 = a01*a12 - a02*a11
    b04 = a01*a13 - a03*a11
    b05 = a02*a13 - a03*a12
    b06 = a20*a31 - a21*a30
    b07 = a20*a32 - a22*a30
    b08 = a20*a33 - a23*a30
    b09 = a21*a32 - a22*a31
    b10 = a21*a33 - a23*a31
    b11 = a22*a33 - a23*a32

  # Calculate the invese determinant
  var invDet = 1.0/(b00*b11 - b01*b10 + b02*b09 + b03*b08 - b04*b07 + b05*b06)

  result[00] = (+a11*b11 - a12*b10 + a13*b09)*invDet
  result[01] = (-a01*b11 + a02*b10 - a03*b09)*invDet
  result[02] = (+a31*b05 - a32*b04 + a33*b03)*invDet
  result[03] = (-a21*b05 + a22*b04 - a23*b03)*invDet
  result[04] = (-a10*b11 + a12*b08 - a13*b07)*invDet
  result[05] = (+a00*b11 - a02*b08 + a03*b07)*invDet
  result[06] = (-a30*b05 + a32*b02 - a33*b01)*invDet
  result[07] = (+a20*b05 - a22*b02 + a23*b01)*invDet
  result[08] = (+a10*b10 - a11*b08 + a13*b06)*invDet
  result[09] = (-a00*b10 + a01*b08 - a03*b06)*invDet
  result[10] = (+a30*b04 - a31*b02 + a33*b00)*invDet
  result[11] = (-a20*b04 + a21*b02 - a23*b00)*invDet
  result[12] = (-a10*b09 + a11*b07 - a12*b06)*invDet
  result[13] = (+a00*b09 - a01*b07 + a02*b06)*invDet
  result[14] = (-a30*b03 + a31*b01 - a32*b00)*invDet
  result[15] = (+a20*b03 - a21*b01 + a22*b00)*invDet

func `*`*(a, b: Mat4): Mat4 =
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

  var
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
    b30 = b[12]
    b31 = b[13]
    b32 = b[14]
    b33 = b[15]

  result[00] = b00*a00 + b01*a10 + b02*a20 + b03*a30
  result[01] = b00*a01 + b01*a11 + b02*a21 + b03*a31
  result[02] = b00*a02 + b01*a12 + b02*a22 + b03*a32
  result[03] = b00*a03 + b01*a13 + b02*a23 + b03*a33
  result[04] = b10*a00 + b11*a10 + b12*a20 + b13*a30
  result[05] = b10*a01 + b11*a11 + b12*a21 + b13*a31
  result[06] = b10*a02 + b11*a12 + b12*a22 + b13*a32
  result[07] = b10*a03 + b11*a13 + b12*a23 + b13*a33
  result[08] = b20*a00 + b21*a10 + b22*a20 + b23*a30
  result[09] = b20*a01 + b21*a11 + b22*a21 + b23*a31
  result[10] = b20*a02 + b21*a12 + b22*a22 + b23*a32
  result[11] = b20*a03 + b21*a13 + b22*a23 + b23*a33
  result[12] = b30*a00 + b31*a10 + b32*a20 + b33*a30
  result[13] = b30*a01 + b31*a11 + b32*a21 + b33*a31
  result[14] = b30*a02 + b31*a12 + b32*a22 + b33*a32
  result[15] = b30*a03 + b31*a13 + b32*a23 + b33*a33

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
  for i in 0..15:
    if abs(a[i] - b[i]) > 0.001:
      return false
  true

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
  result[0] = (near*2) / rl
  result[1] = 0
  result[2] = 0
  result[3] = 0
  result[4] = 0
  result[5] = (near*2) / tb
  result[6] = 0
  result[7] = 0
  result[8] = (right + left) / rl
  result[9] = (top + bottom) / tb
  result[10] = -(far + near) / fn
  result[11] = -1
  result[12] = 0
  result[13] = 0
  result[14] = -(far*near*2) / fn
  result[15] = 0

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
  result[0] = 2 / rl
  result[1] = 0
  result[2] = 0
  result[3] = 0
  result[4] = 0
  result[5] = 2 / tb
  result[6] = 0
  result[7] = 0
  result[8] = 0
  result[9] = 0
  result[10] = -2 / fn
  result[11] = 0
  result[12] = -(left + right) / rl
  result[13] = -(top + bottom) / tb
  result[14] = -(far + near) / fn
  result[15] = 1

func lookAt*(eye, center, up: Vec3): Mat4 =
  var
    eyex = eye[0]
    eyey = eye[1]
    eyez = eye[2]
    upx = up[0]
    upy = up[1]
    upz = up[2]
    centerx = center[0]
    centery = center[1]
    centerz = center[2]

  if eyex == centerx and eyey == centery and eyez == centerz:
    return identity()

  var
    # vec3.direction(eye, center, z)
    z0 = eyex - center[0]
    z1 = eyey - center[1]
    z2 = eyez - center[2]

  # normalize (no check needed for 0 because of early return)
  var len = 1/sqrt(z0*z0 + z1*z1 + z2*z2)
  z0 *= len
  z1 *= len
  z2 *= len

  var
    # vec3.normalize(vec3.cross(up, z, x))
    x0 = upy*z2 - upz*z1
    x1 = upz*z0 - upx*z2
    x2 = upx*z1 - upy*z0
  len = sqrt(x0*x0 + x1*x1 + x2*x2)
  if len == 0:
    x0 = 0
    x1 = 0
    x2 = 0
  else:
    len = 1/len
    x0 *= len
    x1 *= len
    x2 *= len

  var
    # vec3.normalize(vec3.cross(z, x, y))
    y0 = z1*x2 - z2*x1
    y1 = z2*x0 - z0*x2
    y2 = z0*x1 - z1*x0

  len = sqrt(y0*y0 + y1*y1 + y2*y2)
  if len == 0:
    y0 = 0
    y1 = 0
    y2 = 0
  else:
    len = 1/len
    y0 *= len
    y1 *= len
    y2 *= len

  result[0] = x0
  result[1] = y0
  result[2] = z0
  result[3] = 0
  result[4] = x1
  result[5] = y1
  result[6] = z1
  result[7] = 0
  result[8] = x2
  result[9] = y2
  result[10] = z2
  result[11] = 0
  result[12] = -(x0*eyex + x1*eyey + x2*eyez)
  result[13] = -(y0*eyex + y1*eyey + y2*eyez)
  result[14] = -(z0*eyex + z1*eyey + z2*eyez)
  result[15] = 1

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
    xs: float32 = if sign(b00 * b01 * b02 * b03) < 0: -1 else: 1
    ys: float32 = if sign(b10 * b11 * b12 * b13) < 0: -1 else: 1
    zs: float32 = if sign(b20 * b21 * b22 * b23) < 0: -1 else: 1

  result.x = xs * sqrt(b00 * b00 + b01 * b01 + b02 * b02)
  result.y = ys * sqrt(b10 * b10 + b11 * b11 + b12 * b12)
  result.z = zs * sqrt(b20 * b20 + b21 * b21 + b22 * b22)

func `$`*(a: Mat4): string =
  &"""[{a[0]:.5f}, {a[1]:.5f}, {a[2]:.5f}, {a[3]:.5f},
{a[4]:.5f}, {a[5]:.5f}, {a[6]:.5f}, {a[7]:.5f},
{a[8]:.5f}, {a[9]:.5f}, {a[10]:.5f}, {a[11]:.5f},
{a[12]:.5f}, {a[13]:.5f}, {a[14]:.5f}, {a[15]:.5f}]"""

func caddr*(m: var Mat4): ptr float32 = m[0].addr

