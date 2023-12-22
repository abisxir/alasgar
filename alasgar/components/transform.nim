import ../core

proc lookAt*(t: TransformComponent, target: Vec3, up: Vec3 = VEC3_UP) = t.globalRotation = quat(lookAt(t.globalPosition, target, up))
proc lookAt*(t: TransformComponent, target: TransformComponent, up: Vec3 = VEC3_UP) = lookAt(t, target.globalPosition, up)

