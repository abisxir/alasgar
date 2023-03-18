import ../core
import ../shader
import ../texture
import ../system
import ../render/fb

const forwardPostV = staticRead("../render/shaders/fullscreen.vs")
const forwardPostF = staticRead("../render/shaders/effect.fs")

type
    PostProcessingComponent* = ref object of Component
        shader*: Shader        

    PostProcessingSystem* = ref object of System

proc newPostProcessingComponent*(source: string): PostProcessingComponent  =
    new(result)
    result.shader = newShader(forwardPostV, forwardPostF.replace("$MAIN_FUNCTION$", source), [])

method cleanup*(c: PostProcessingComponent) =
    if(c.shader != nil):
        destroy(c.shader)
        c.shader = nil

proc newPostProcessingSystem*(): PostProcessingSystem =
    new(result)

method process(sys: PostProcessingSystem, scene: Scene, input: Input, delta: float32, frames: float32, age: float32) =
    for c in iterateComponents[PostProcessingComponent](scene):
        #sys.graphics.context
        discard

