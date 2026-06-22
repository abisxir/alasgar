import math
import common, vec3, vec4

func quat*(v: Vec3): Quat = Quat(x: v.x, y: v.y, z: v.z, w: 0.0)
func quat*(x, y, z, w: float32): Quat = Quat(x: x, y: y, z: z, w: w)
func quat*(w: float32): Quat = Quat(x: 0.0, y: 0.0, z: 0.0, w: w)
func quat*(): Quat = Quat(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
func quat*(v: openArray[float32], offset: int): Quat = quat(v[offset], v[offset + 1], v[offset + 2], v[offset + 3])

func fromEuler*(yaw, pitch, roll: float32): Quat =
  let
    cy = cos(yaw * 0.5)
    sy = sin(yaw * 0.5)
    cp = cos(pitch * 0.5)
    sp = sin(pitch * 0.5)
    cr = cos(roll * 0.5)
    sr = sin(roll * 0.5)
  Quat(
    w: cr * cp * cy + sr * sp * sy,
    x: sr * cp * cy - cr * sp * sy,
    y: cr * sp * cy + sr * cp * sy,
    z: cr * cp * sy - sr * sp * cy
  )

func fromEuler*(v: Vec3): Quat = fromEuler(v.x, v.y, v.z)

func euler*(q1: Quat): Vec3 =
  let
    sqw = q1.w * q1.w
    sqx = q1.x * q1.x
    sqy = q1.y * q1.y
    sqz = q1.z * q1.z
    unit = sqx + sqy + sqz + sqw # if normalised is one, otherwise is correction factor
    test = q1.x * q1.y + q1.z * q1.w
  if test > 0.499 * unit: # singularity at north pole
    result.y = 2 * arctan2(q1.x, q1.w)
    result.z = PI / 2
    result.x = 0
  elif test < -0.499 * unit: # singularity at south pole
    result.y = -2 * arctan2(q1.x, q1.w)
    result.z = -PI / 2
    result.x = 0
  else:
    result.y = arctan2(2 * q1.y * q1.w - 2 * q1.x * q1.z, sqx - sqy - sqz + sqw)
    result.z = arcsin(2 * test / unit)
    result.x = arctan2(2 * q1.x * q1.w - 2 * q1.y * q1.z, -sqx + sqy - sqz + sqw)

func `*`*(q, p: Quat): Quat = Quat(
  x: p.x * q.w + p.y * q.z - p.z * q.y + p.w * q.x,
  y: -(p.x * q.z) + p.y * q.w + p.z * q.x + p.w * q.y,
  z: p.x * q.y - p.y * q.x + p.z * q.w + p.w * q.z,
  w: -(p.x * q.x) - p.y * q.y - p.z * q.z + p.w * q.w
)

func `*`*(q: Quat, v: Vec3): Vec3 =
  let
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

  return vec3(
    ix * qw + iw * -qx + iy * -qz - iz * -qy,
    iy * qw + iw * -qy + iz * -qx - ix * -qz,
    iz * qw + iw * -qz + ix * -qy - iy * -qx
  )

func `*`*(v: Vec3, q: Quat): Vec3 =
  let
    u = vec3(q.x, q.y, q.z)
    s = q.w
  return vec3(2 * dot(u, v) * u) + ((s * s - dot(u, u)) * v) + (2 * s * cross(u, v))

func rotate*(v: Vec3, q: Quat): Vec3 = v * q

func conjugate*(quat: Quat): Quat =
  Quat(
    x: quat.x * -1.0,
    y: quat.y * -1.0,
    z: quat.z * -1.0,
    w: quat.w
  )

func inverse*(quat: Quat): Quat =
  let
    norm = quat.x * quat.x + quat.y * quat.y + quat.z * quat.z + quat.w * quat.w
    recip = -1.0 / norm
  Quat(
    x: quat.x * recip,
    y: quat.y * recip,
    z: quat.z * recip,
    w: quat.w * -recip
  )

func nlerp*(sq, eq: Quat, t: float32): Quat =
  var ne = eq
  if dot(sq, eq) < 0:
    ne = -1 * eq
  # start + (end - start) * t
  normalize(sq + t * (ne - sq))

func slerp*(a, b: Quat, t: float32): Quat =
  var
    q1 = normalize(a)
    q2 = normalize(b)
    aob = dot(q1, q2)
    THRESHOLD = 0.9995'f32

  # If the dot product is negative, invert one quaternion to take the shortest path
  if aob < 0.0:
    q2 = -1 * q2
    aob = -aob

  # If the dot product is close to 1, use linear interpolation to avoid division by zero
  if aob > THRESHOLD:
    # Perform a simple linear interpolation
    result.w = q1.w + t * (q2.w - q1.w)
    result.x = q1.x + t * (q2.x - q1.x)
    result.y = q1.y + t * (q2.y - q1.y)
    result.z = q1.z + t * (q2.z - q1.z)
  else:
    # Calculate the angle between the quaternions
    let
      theta_0 = arccos(aob)      # theta_0 is the angle between input quaternions
      theta = theta_0 * t        # theta is the angle after interpolation
      sin_theta = sin(theta)     # Compute sin(theta)
      sin_theta_0 = sin(theta_0) # Compute sin(theta_0)
                                  # Calculate the two interpolated quaternions
      s1 = cos(theta) - aob * sin_theta / sin_theta_0
      s2 = sin_theta / sin_theta_0
    result.w = (q1.w * s1) + (q2.w * s2)
    result.x = (q1.x * s1) + (q2.x * s2)
    result.y = (q1.y * s1) + (q2.y * s2)
    result.z = (q1.z * s1) + (q2.z * s2)

  result = normalize(result)

func mix*(s, e: Quat, t: float32): Quat =
  var tt = t
  if dot(s, e) < 0:
    tt = -t
  # start * (1 - t) + end * t
  result = normalize(s * (1 - t) + e * tt)

func pow*(q: Quat, power: float32): Quat =
  let
    angle = 2'f32 * arccos(q.w)
    axis: Vec3 = normalize(vec3(q.x, q.y, q.z))

  let halfCos = cos((power * angle) * 0.5)
  let halfSin = sin((power * angle) * 0.5)

  Quat(x: axis.x * halfSin, y: axis.y * halfSin, z: axis.z * halfSin, w: halfCos)

func angleAxis*(radians: float32, axis: Vec3): Quat =
  var
    half: float32 = radians * 0.5'f32
    sinHalf = sin(half)
    a = axis
  if lengthSq(a) != 1:
    a = normalize(axis)

  return Quat(
    x: axis.x * sinHalf,
    y: axis.y * sinHalf,
    z: axis.z * sinHalf,
    w: cos(half)
  )

proc fromToRotation*(a, b: Vec3): Quat =
  let
    p0 = normalize(a)
    p1 = normalize(b)
  if p0 == -1 * p1:
    var mostOrthogonal = vec3(1, 0, 0)
    if abs(p0.y) < abs(p0.x):
      mostOrthogonal = vec3(0, 1, 0)
    if abs(p0.z) < abs(p0.y) and abs(p0.z) < abs(p0.x):
      mostOrthogonal = vec3(0, 0, 1)
    let axis = normalize(cross(p0, mostOrthogonal))
    result = quat(axis.x, axis.y, axis.z, 0)
  else:
    let
      half = normalize(p0 + p1)
      axis = cross(p0, half)
    result = quat(axis.x, axis.y, axis.z, dot(p0, half))

func lookAt*(direction: Vec3, up: Vec3 = vec3(0, 1, 0)): Quat =
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
  normalize(q)

func mat4*(q: Quat): Mat4 =
  let
    ww = q.w * q.w
    xx = q.x * q.x
    yy = q.y * q.y
    zz = q.z * q.z
    wx = q.w * q.x
    wy = q.w * q.y
    wz = q.w * q.z
    xy = q.x * q.y
    xz = q.x * q.z
    yz = q.y * q.z

  return (
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

func quat*(p: ptr float32, offset: int = 0): Quat =
  var
    address = cast[uint](p)
    size = sizeof(float32).uint
    start = address + offset.uint * sizeof(float32).uint
    x = cast[ptr float32](start)
    y = cast[ptr float32](start + size)
    z = cast[ptr float32](start + 2 * size)
    w = cast[ptr float32](start + 3 * size)
  result = quat(x[], y[], z[], w[])
