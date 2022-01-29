import ../core
import ../utils
import ../system
import ../render/graphic


type
    ShaderSystem* = ref object of System

# System implementation
proc newShaderSystem*(): ShaderSystem =
    new(result)
    result.name = "Shader System"

method process*(sys: ShaderSystem, scene: Scene, input: Input, delta: float32, frames: float32, age: float32) =
    if scene.root != nil:
        for c in iterateComponents[ShaderComponent](scene):
            discard
