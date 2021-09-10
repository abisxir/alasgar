import ../math/vec4
import ../math/vec3

type
    Plane* = Vec4

func distanceTo*(plane: Plane, pt: Vec3): float32 =
    result = plane.x * pt.x + plane.y * pt.y + plane.z * pt.z + plane.w
