#import threadpool
#{.experimental: "parallel".}
import ../system
import ../utils

type
    TraverseSystem* = ref object of System

proc newTraverseSystem*(): TraverseSystem =
    new(result)
    result.name = "Traverse"

proc traverse(e: Entity, world: Mat4, dirty: bool) =
    let isEntityDirty = dirty or e.transform.dirty
    var model = rebase(e, world, dirty)

    if e.getChildrenCount() > 0:
        for child in e.children:
            if child.attached:
                traverse(child, model, isEntityDirty)
                


#proc update(t: TransformComponent, cache: var Table[TransformComponent, Mat4]): Mat4 =
#    var pm = world
#    var current = t.parent
#    while current != nil:
#        pm = pm * current.model
#        current = current.parent
#    result


method process*(sys: TraverseSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) =
    if scene.root != nil:
        let world = mat4()
        traverse(scene.root, world, false)
        #var cache = initTable[TransformComponent, Mat4]()
        #for transform in iterate[TransformComponent](scene):
        #    update(transform, cache)


