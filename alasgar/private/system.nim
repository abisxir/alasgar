import core
import render/graphic

export core, graphic, transform

# System implementation
type
    System* = ref object of RootObj
        name*: string
        graphic*: Graphic


method init*(sys: System, g: Graphic) {.base, locks: "unknown".} = sys.graphic = g
method process*(sys: System, scene: Scene, input: Input, delta: float32, frames: float32, age: float32) {.base, locks: "unknown".} = discard
method cleanup*(sys: System) {.base, locks: "unknown".} = discard

