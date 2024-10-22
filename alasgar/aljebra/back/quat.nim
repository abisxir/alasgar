import helpers
import types
import vec3
import mat4

export types

func quat*(x, y, z, w: float32): Quat =
    result.x = x
    result.y = y
    result.z = z
    result.w = w

func quat*(v: Vec3): Quat =
    result.x = v.x
    result.y = v.y
    result.z = v.z
    result.w = 0

func quat*(): Quat =
    result.x = 0
    result.y = 0
    result.z = 0
    result.w = 1

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

func euler*(q1: Quat): Vec3 =
    let sqw = q1.w * q1.w
    let sqx = q1.x * q1.x
    let sqy = q1.y * q1.y
    let sqz = q1.z * q1.z
    let unit = sqx + sqy + sqz + sqw # if normalised is one, otherwise is correction factor
    let test = q1.x * q1.y + q1.z * q1.w
    if test > 0.499 * unit: # singularity at north pole
        result.y = 2 * arctan2(q1.x, q1.w)
        result.z = PI / 2
        result.x = 0
    elif test < -0.499 * unit: # singularity at south pole
        result.y = -2 * arctan2(q1.x, q1.w)
        result.z = -PI / 2
        result.x = 0
    else:
        result.y = arctan2(2 * q1.y * q1.w - 2 * q1.x * q1.z , sqx - sqy - sqz + sqw)
        result.z = arcsin(2 * test / unit)
        result.x = arctan2(2 * q1.x * q1.w - 2 * q1.y * q1.z , -sqx + sqy - sqz + sqw)    

func `+`*(left, right: Quat): Quat =
    result.x = left.x + right.x
    result.y = left.y + right.y
    result.z = left.z + right.z
    result.w = left.w + right.w

func `-`*(left, right: Quat): Quat =
    result.x = left.x - right.x
    result.y = left.y - right.y
    result.z = left.z - right.z
    result.w = left.w - right.w

func `*`*(q: Quat, scalar: float32): Quat =
    result.x = q.x * scalar
    result.y = q.y * scalar
    result.z = q.z * scalar
    result.w = q.w * scalar

func `*`*(scalar: float32, q: Quat): Quat =
    result.x = q.x * scalar
    result.y = q.y * scalar
    result.z = q.z * scalar
    result.w = q.w * scalar

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

func `*`*(v: Vec3, q: Quat): Vec3 =
    var u = vec3(q.x, q.y, q.z)
    var s = q.w
    result = (2 * dot(u, v) * u) + ((s * s - dot(u, u)) * v) + (2 * s * cross(u, v))

func rotate*(v: Vec3, q: Quat): Vec3 = v * q



func almostEquals*(left, right: Quat): bool =
    result = 
        abs(left.x - right.x) <= EPSILON and 
        abs(left.y - right.y) <= EPSILON and 
        abs(left.z - right.z) <= EPSILON and 
        abs(left.w - left.w) <= EPSILON

func dot*(left, right: Quat): float32 =
    left.x * right.x + left.y * right.y + left.z * right.z + left.w * right.w

func lengthSq*(quat: Quat): float32 =
    quat.x * quat.x + quat.y * quat.y + quat.z * quat.z + quat.w * quat.w

func length*(quat: Quat): float32 =
    sqrt(lengthSq(quat))

func normalize*(quat: Quat): Quat =
    let lengthSq = quat.x * quat.x + quat.y * quat.y + quat.z * quat.z + quat.w * quat.w
    if lengthSq != 0:
        let invLen = 1.0'f32 / sqrt(lengthSq)
        result.x = quat.x * invLen
        result.y = quat.y * invLen
        result.z = quat.z * invLen
        result.w = quat.w * invLen

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

func nlerp*(sq, eq: Quat, t: float32): Quat =
    var ne = eq
    if dot(sq, eq) < 0:
        ne = -1 * eq
    # start + (end - start) * t
    result = normalize(sq + t * (ne - sq))

func mix*(s, e: Quat, t: float32): Quat =
    var dot = dot(s, e)
    var tt = if dot < 0: -t else: t

    # start * (1 - t) + end * t
    result = normalize(s * (1 - t) + e * tt)

func pow*(q: Quat, power: float32): Quat =
    let angle = 2'f32 * arccos(q.w)
    let axis = normalize(vec3(q.x, q.y, q.z))

    let halfCos = cos((power * angle) * 0.5)
    let halfSin = sin((power * angle) * 0.5)

    result.x = axis.x * halfSin
    result.x = axis.y * halfSin
    result.x = axis.z * halfSin
    result.x = halfCos 

func slerp*(a, b: Quat, t: float32): Quat =
    var s = a
    var e = b
    if dot(a, b) < 0:
        e = -1 * e
    return pow(e * inverse(s), t) * s

func angleAxis*(radians: float32, axis: Vec3): Quat =
    var half: float32 = radians * 0.5'f32
    var sinHalf = sin(half)
    var a = axis
    if lengthSq(a) != 1:
        a = normalize(axis)

    result.x = axis.x * sinHalf
    result.y = axis.y * sinHalf
    result.z = axis.z * sinHalf
    result.w = cos(half)

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

func mat4*(q: Quat): Mat4 =
    let ww = q.w * q.w
    let xx = q.x * q.x
    let yy = q.y * q.y
    let zz = q.z * q.z

    let wx = q.w * q.x
    let wy = q.w * q.y
    let wz = q.w * q.z

    let xy = q.x * q.y
    let xz = q.x * q.z

    let yz = q.y * q.z

    result = mat4(
        ww + xx - yy - zz, 2 * xy - 2 * wz, 2 * xz + 2 * wy, 0,
        2 * xy + 2 * wz, ww - xx + yy - zz, 2 * yz - 2 * wx, 0,
        2 * xz - 2 * wy, 2 * yz + 2 * wx, ww - xx - yy + zz, 0,
        0, 0, 0, ww + xx + yy + zz
    )

func quat*(m: Mat4): Quat =
    var up = normalize(vec3(m[0], m[1], m[2]))
    var forward = normalize(vec3(m[8], m[9], m[10]))
    var right = cross(up, forward)
    up = cross(forward, right)

    result = lookAt(forward, up)


func quat*(p: ptr float32, offset: int=0): Quat =
    let 
        address = cast[ByteAddress](p)
        x = cast[ptr float32](address + offset * sizeof(float32))
        y = cast[ptr float32](address + (offset + 1) * sizeof(float32))
        z = cast[ptr float32](address + (offset + 2) * sizeof(float32))
        w = cast[ptr float32](address + (offset + 3) * sizeof(float32))
    result = quat(x[], y[], z[], w[])    

#[
func euler*(m: var Mat4): Vec3 = 
    var yaw, pitch, roll: float32
    if m[0] == 1.0 or m[0] == -1.0:
        yaw = arctan2(m[2], m[11])
        pitch = 0
        roll = 0
    else:
        yaw = arctan2(-m[8], m[0])
        pitch = arcsin(m[4])
        roll = arctan2(-m[6], m[5])
    vec3(yaw, pitch, roll)

proc toEuler*(q1: Quat): Vec3 =
    let sqw = q1.w * q1.w
    let sqx = q1.x * q1.x
    let sqy = q1.y * q1.y
    let sqz = q1.z * q1.z
    let unit = sqx + sqy + sqz + sqw # if normalised is one, otherwise is correction factor
    let test = q1.x * q1.y + q1.z * q1.w
    if test > 0.499 * unit: # singularity at north pole
        result.y = 2 * arctan2(q1.x, q1.w)
        result.z = PI / 2
        result.x = 0
    elif test < -0.499 * unit: # singularity at south pole
        result.y = -2 * arctan2(q1.x, q1.w)
        result.z = -PI / 2
        result.x = 0
    else:
        result.y = arctan2(2 * q1.y * q1.w - 2 * q1.x * q1.z , sqx - sqy - sqz + sqw)
        result.z = arcsin(2 * test / unit)
        result.x = arctan2(2 * q1.x * q1.w - 2 * q1.y * q1.z , -sqx + sqy - sqz + sqw)    
]#

