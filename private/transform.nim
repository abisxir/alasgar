import common

type
  Transform* = object
    position*: Vec3
    scale*: Vec3 = Vec3(x: 1.0, y: 1.0, z: 1.0)
    rotation*: Quat = Quat(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
    parent*: ptr Mat4


## Transform
func `mat4`*(t: Transform): Mat4 =
  var
    x = t.rotation * vec3(1, 0, 0) # Vec3 * Quat (right vector)
    y = t.rotation * vec3(0, 1, 0) # Vec3 * Quat (up vector)
    z = t.rotation * vec3(0, 0, 1) # Vec3 * Quat (forward vector)

  # Next, scale the basis vectors
  x = x * t.scale.x # Vector * float
  y = y * t.scale.y # Vector * float
  z = z * t.scale.z # Vector * float

  # Create matrix
  result = mat4(
    x.x, x.y, x.z, 0, # X basis (& Scale)
    y.x, y.y, y.z, 0, # Y basis (& scale)
    z.x, z.y, z.z, 0, # Z basis (& scale)
    t.position.x, t.position.y, t.position.z, 1 # Position
  )
func `local`*(t: Transform): Mat4 = t.mat4
func `world`*(t: Transform): Mat4 =
  if not isNil(t.parent):
    t.parent[] * t.mat4
  else:
    t.mat4

proc lookAt*(t: var Transform, target: Vec3, up: Vec3) =
  let
    world = t.world
    worldPosition = world.pos
  t.rotation = lookAt(worldPosition - target, up)
  if not isNil(t.parent):
    t.rotation = inverse(t.parent[].quat) * t.rotation
