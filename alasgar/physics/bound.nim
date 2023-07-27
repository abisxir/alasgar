import ../core
import collision
import tools
import ray

type
    Bound* = ref object of RootObj
        scale*: Vec3
        center*: Vec3

    BoxBound* = ref object of Bound
        vMin, vMax: Vec3

    SphereBound* = ref object of Bound
        radius: float32

method intersects*(bound: Bound, ray: Ray): Collision {.base.} = discard
method intersects*(bound: Bound, other: Bound): Collision {.base.} = discard
method getBoundRadius(bound: Bound): float32 {.base.} = discard

proc newBoxBound*(vMin, vMax: Vec3): BoxBound =
    new(result)
    result.vMin = vMin
    result.vMax = vMax
    result.scale = VEC3_ONE


proc min(box: BoxBound): Vec3 = box.center + (box.vMin * box.scale)
proc max(box: BoxBound): Vec3 = box.center + (box.vMax * box.scale)


method intersects*(box: BoxBound, ray: Ray): Collision =
    var intersectPoint: Vec3
    if isRayIntersectsBox(ray.origin, ray.normalizedDirection, ray.inversedNormalizedDirection, ray.length, min(box), max(box), addr(intersectPoint)):
        result = newCollision(intersectPoint)
    #if isRayIntersectsBox(ray.origin, ray.normalizedDirection, ray.length, min(box), max(box), addr(intersectPoint)):
    #    result = newCollision(intersectPoint)
        

method intersects*(box: BoxBound, bound: Bound): Collision =
    if bound of BoxBound:
        var other = cast[BoxBound](bound)
        if isBoxIntersectsBox(min(box), max(box), min(other), max(other)):
            result = newCollision()
    elif bound of SphereBound:
        var other = cast[SphereBound](bound)
        if isSphereIntersectsBox(other.center, other.radius, min(box), max(box)):
            result = newCollision()

method getBoundRadius(box: BoxBound): float32 = length(max(box) - min(box)) / 2.float32

proc newSphereBound*(radius: float32): SphereBound =
    new(result)
    result.radius = radius
    result.scale = VEC3_ONE

method intersects*(sphere: SphereBound, ray: Ray): Collision =
    var p1, p2: Vec3
    if isRayIntersectsSphere(ray.origin, ray.normalizedDirection, ray.length,
            sphere.center, sphere.radius * sphere.scale.x, addr(p1), addr(p2)):
        result = newCollision(p1, p2)

method intersects*(sphere: SphereBound, bound: Bound): Collision =
    if bound of SphereBound:
        var other = cast[SphereBound](bound)
        if isSphereIntersectsSphere(sphere.center, sphere.radius * sphere.scale.x, other.center, other.radius):
            result = newCollision()
    elif bound of BoxBound:
        var other = cast[BoxBound](bound)
        if isSphereIntersectsBox(sphere.center, sphere.radius * sphere.scale.x, min(other), max(other)):
            result = newCollision()

method getBoundRadius(sphere: SphereBound): float32 = sphere.radius
