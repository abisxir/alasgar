import core

export core, transform

# System implementation
type
    System* = ref object of RootObj
        name*: string

var systems = newSeq[System]()

method process*(sys: System, scene: Scene, input: Input, delta: float32, frames: int, age: float32) {.base.} = discard
method cleanup*(sys: System) {.base.} = discard
method init*(sys: System) {.base.} = add(systems, sys)

proc getSystem*[T](): T = 
    for sys in systems:
        if sys of T:
            return cast[T](sys)

