import ../core
import ../physics/ray
import ../physics/collision
import ../physics/bound


type
    CollisionComponent* = ref object of Component
        offset: Vec3
        bound: Bound


proc newCollisionComponent*(radius: float32, offset: Vec3=VEC3_ZERO): CollisionComponent =
    new(result)
    result.bound = newSphereBound(radius)
    result.offset = offset


proc newCollisionComponent*(vMin, vMax: Vec3, offset: Vec3=VEC3_ZERO): CollisionComponent =
    new(result)
    result.bound = newBoxBound(vMin, vMax)
    result.offset = offset

proc addBoundingBox*(e: Entity) =
    let mesh = e[MeshComponent]
    if mesh != nil:
        add(e, newCollisionComponent(mesh.instance.vMin, mesh.instance.vMax))
    else:
        add(e, newCollisionComponent(vec3(-1, -1, -1), vec3(1, 1, 1)))

proc addBoundingSphere*(e: Entity) =
    let mesh = e[MeshComponent]
    if mesh != nil:
        add(e, newCollisionComponent(mesh.instance.vRadius))
    else:
        add(e, newCollisionComponent(1.0))

proc intersects*(c: CollisionComponent, ray: Ray): Collision =
    c.bound.center = c.offset + c.transform.globalPosition
    c.bound.scale = c.transform.globalScale
    result = intersects(c.bound, ray)
    if result != nil:
        result.collider = c.entity


