import helpers
import types
import vector

## 4x4 Matrix - OpenGL row order
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

func mat4*(m: array[16, float32]): Mat4 =
    result[0] = m[0]
    result[1] = m[1]
    result[2] = m[2]
    result[3] = m[3]
    result[4] = m[4]
    result[5] = m[5]
    result[6] = m[6]
    result[7] = m[7]
    result[8] = m[8]
    result[9] = m[9]
    result[10] = m[10]
    result[11] = m[11]
    result[12] = m[12]
    result[13] = m[13]
    result[14] = m[14]
    result[15] = m[15]

func mat4*(): Mat4 =
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

func mat4*(v0, v1, v2, v3: Vec4): Mat4 =
    result[0] = v0.x
    result[1] = v0.y
    result[2] = v0.z
    result[3] = v0.w

    result[4] = v1.x
    result[5] = v1.y
    result[6] = v1.z
    result[7] = v1.w

    result[8] = v2.x
    result[9] = v2.y
    result[10] = v2.z
    result[11] = v2.w

    result[12] = v3.x
    result[13] = v3.y
    result[14] = v3.z
    result[15] = v3.w

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

    result[00] = (+a.m11*b11 - a.m12*b10 + a.m13*b09)*invDet
    result[01] = (-a.m01*b11 + a.m02*b10 - a.m03*b09)*invDet
    result[02] = (+a.m31*b05 - a.m32*b04 + a.m33*b03)*invDet
    result[03] = (-a.m21*b05 + a.m22*b04 - a.m23*b03)*invDet
    result[04] = (-a.m10*b11 + a.m12*b08 - a.m13*b07)*invDet
    result[05] = (+a.m00*b11 - a.m02*b08 + a.m03*b07)*invDet
    result[06] = (-a.m30*b05 + a.m32*b02 - a.m33*b01)*invDet
    result[07] = (+a.m20*b05 - a.m22*b02 + a.m23*b01)*invDet
    result[08] = (+a.m10*b10 - a.m11*b08 + a.m13*b06)*invDet
    result[09] = (-a.m00*b10 + a.m01*b08 - a.m03*b06)*invDet
    result[10] = (+a.m30*b04 - a.m31*b02 + a.m33*b00)*invDet
    result[11] = (-a.m20*b04 + a.m21*b02 - a.m23*b00)*invDet
    result[12] = (-a.m10*b09 + a.m11*b07 - a.m12*b06)*invDet
    result[13] = (+a.m00*b09 - a.m01*b07 + a.m02*b06)*invDet
    result[14] = (-a.m30*b03 + a.m31*b01 - a.m32*b00)*invDet
    result[15] = (+a.m20*b03 - a.m21*b01 + a.m22*b00)*invDet

func `*`*(a, b: Mat4): Mat4 =
    result[00] = b.m00*a.m00 + b.m01*a.m10 + b.m02*a.m20 + b.m03*a.m30
    result[01] = b.m00*a.m01 + b.m01*a.m11 + b.m02*a.m21 + b.m03*a.m31
    result[02] = b.m00*a.m02 + b.m01*a.m12 + b.m02*a.m22 + b.m03*a.m32
    result[03] = b.m00*a.m03 + b.m01*a.m13 + b.m02*a.m23 + b.m03*a.m33
    result[04] = b.m10*a.m00 + b.m11*a.m10 + b.m12*a.m20 + b.m13*a.m30
    result[05] = b.m10*a.m01 + b.m11*a.m11 + b.m12*a.m21 + b.m13*a.m31
    result[06] = b.m10*a.m02 + b.m11*a.m12 + b.m12*a.m22 + b.m13*a.m32
    result[07] = b.m10*a.m03 + b.m11*a.m13 + b.m12*a.m23 + b.m13*a.m33
    result[08] = b.m20*a.m00 + b.m21*a.m10 + b.m22*a.m20 + b.m23*a.m30
    result[09] = b.m20*a.m01 + b.m21*a.m11 + b.m22*a.m21 + b.m23*a.m31
    result[10] = b.m20*a.m02 + b.m21*a.m12 + b.m22*a.m22 + b.m23*a.m32
    result[11] = b.m20*a.m03 + b.m21*a.m13 + b.m22*a.m23 + b.m23*a.m33
    result[12] = b.m30*a.m00 + b.m31*a.m10 + b.m32*a.m20 + b.m33*a.m30
    result[13] = b.m30*a.m01 + b.m31*a.m11 + b.m32*a.m21 + b.m33*a.m31
    result[14] = b.m30*a.m02 + b.m31*a.m12 + b.m32*a.m22 + b.m33*a.m32
    result[15] = b.m30*a.m03 + b.m31*a.m13 + b.m32*a.m23 + b.m33*a.m33


func `+`*(a, b: Mat4): Mat4 =
    result[00] = a[0] + b[0]
    result[01] = a[1] + b[1]
    result[02] = a[2] + b[2]
    result[03] = a[3] + b[3]
    result[04] = a[4] + b[4]
    result[05] = a[5] + b[5]
    result[06] = a[6] + b[6]
    result[07] = a[7] + b[7]
    result[08] = a[8] + b[8]
    result[09] = a[9] + b[9]
    result[10] = a[10] + b[10]
    result[11] = a[11] + b[11]
    result[12] = a[12] + b[12]
    result[13] = a[13] + b[13]
    result[14] = a[14] + b[14]
    result[15] = a[15] + b[15]

func `*`*(f: float32, m: Mat4): Mat4 =
    result[0] = m[0] * f
    result[1] = m[1] * f
    result[2] = m[2] * f
    result[3] = m[3] * f
    result[4] = m[4] * f
    result[5] = m[5] * f
    result[6] = m[6] * f
    result[7] = m[7] * f
    result[8] = m[8] * f
    result[9] = m[9] * f
    result[10] = m[10] * f
    result[11] = m[11] * f
    result[12] = m[12] * f
    result[13] = m[13] * f
    result[14] = m[14] * f
    result[15] = m[15] * f

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
        return mat4()

    var
        # vec3.direction(eye, center, z)
        z0 = eyex - center[0]
        z1 = eyey - center[1]
        z2 = eyez - center[2]
        # normalize (no check needed for 0 because of early return)
        len = 1/sqrt(z0*z0 + z1*z1 + z2*z2)
    
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
        xs: float32 = if sgn(b00 * b01 * b02 * b03) < 0: -1 else: 1
        ys: float32 = if sgn(b10 * b11 * b12 * b13) < 0: -1 else: 1
        zs: float32 = if sgn(b20 * b21 * b22 * b23) < 0: -1 else: 1

    result.x = xs * sqrt(b00 * b00 + b01 * b01 + b02 * b02)
    result.y = ys * sqrt(b10 * b10 + b11 * b11 + b12 * b12)
    result.z = zs * sqrt(b20 * b20 + b21 * b21 + b22 * b22)

func mat3*(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9: float32): Mat3 =
    result[0] = v0
    result[1] = v1
    result[2] = v2
    result[3] = v3
    result[4] = v4
    result[5] = v5
    result[6] = v6
    result[7] = v7
    result[8] = v8

func mat3*(v1, v2, v3: Vec3): Mat3 =
    result[0] = v1.x
    result[1] = v1.y
    result[2] = v1.z
    result[3] = v2.x
    result[4] = v2.y
    result[5] = v2.z
    result[6] = v3.x
    result[7] = v3.y
    result[8] = v3.z

func mat3*(v: float32): Mat3 =
    result[0] = v
    result[1] = v
    result[2] = v
    result[3] = v
    result[4] = v
    result[5] = v
    result[6] = v
    result[7] = v
    result[8] = v

func mat3*(): Mat3 =
    result[0] = 1
    result[1] = 0
    result[2] = 0
    result[3] = 0
    result[4] = 1
    result[5] = 0
    result[6] = 0
    result[7] = 0
    result[8] = 1

func `*`*(f: float32, m: Mat3): Mat3 =
    result[0] = m[0] * f
    result[1] = m[1] * f
    result[2] = m[2] * f
    result[3] = m[3] * f
    result[4] = m[4] * f
    result[5] = m[5] * f
    result[6] = m[6] * f
    result[7] = m[7] * f
    result[8] = m[8] * f

func `*`*(m: Mat3, f: float32): Mat3 = f * m

func `*`*(m: Mat3, v: Vec3): Vec3 =
    result.x = m.m00 * v.x + m.m01 * v.y + m.m02 * v.z
    result.y = m.m10 * v.x + m.m11 * v.y + m.m12 * v.z
    result.z = m.m20 * v.x + m.m21 * v.y + m.m22 * v.z

func caddr*(m: var Mat4): ptr float32 = m[0].addr

