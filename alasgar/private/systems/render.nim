import hashes
#import threadpool
#{.experimental: "parallel".}

import ../core
import ../system
import ../render/graphic

type
    RenderSystem* = ref object of System

proc newRenderSystem*(): RenderSystem =
    new(result)
    result.name = "Render System"

method process*(sys: RenderSystem, scene: Scene, input: Input, delta: float32) =
       
    # Sends data to GPU
    render(sys.graphic, scene.drawables)

    # Swaps buffers
    swap(sys.graphic)

