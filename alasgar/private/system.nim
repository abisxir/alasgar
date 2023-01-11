import core
import render/graphic

export core, graphic, transform

# System implementation
type
    System* = ref object of RootObj
        name*: string
        graphic*: Graphic

var systems = newSeq[System]()

method process*(sys: System, scene: Scene, input: Input, delta: float32, frames: float32, age: float32) {.base.} = discard
method cleanup*(sys: System) {.base.} = discard
method init*(sys: System, g: Graphic) {.base.} = 
    sys.graphic = g
    add(systems, sys)

proc getSystem*[T](): T = 
    for sys in systems:
        if sys of T:
            return cast[T](sys)

