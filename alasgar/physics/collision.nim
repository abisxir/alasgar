import ../core

type
    Collision* = ref object
        points*: seq[Vec3]
        collider*: Entity

func newCollision*(): Collision = new(result)

func newCollision*(p1: Vec3): Collision = 
    new(result)
    result.points.add(p1)

func newCollision*(p1, p2: Vec3): Collision = 
    new(result)
    result.points.add(p1)
    result.points.add(p1)

