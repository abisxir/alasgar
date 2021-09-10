import ../utils

type 
    Ray* = object
        origin: Vec3
        direction: Vec3
        normalizedDirection: Vec3
        inversedNormalizedDirection: Vec3
        length: float32

proc update(ray: var Ray) =
    ray.normalizedDirection = normalize(ray.direction)
    ray.inversedNormalizedDirection = 1 / ray.normalizedDirection
    ray.length = length(ray.direction - ray.origin)

func newRay*(origin: Vec3, direction: Vec3): Ray =
    result.origin = origin
    result.direction = direction
    update(result)

template `direction=`*(r: var Ray, value: Vec3) =
    r.direction = value
    update(r)

template `origin`*(r: Ray): Vec3 = r.origin
template `direction`*(r: Ray): Vec3 = r.direction
template `normalizedDirection`*(r: Ray): Vec3 = r.normalizedDirection
template `inversedNormalizedDirection`*(r: Ray): Vec3 = r.inversedNormalizedDirection
template `length`*(r: Ray): float32 = r.length

func `$`*(r: Ray): string = 
    result = &"{r.origin} -> {r.normalizedDirection} * {r.length}"
