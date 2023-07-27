import ../core
import ../system
import ../components/camera
import ../components/environment
import ../render/gpu

type
    RenderSystem* = ref object of System

proc newRenderSystem*(): RenderSystem =
    new(result)
    result.name = "Render System"

method process*(sys: RenderSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) =  
    let 
        # Gets active camera, it is needed for getting view and projection matrix
        camera = scene.activeCamera
        # Gets environment component
        env = first[EnvironmentComponent](scene)
        # Gets cubemap if there is env
        skybox = if not isNil(env): env.environmentMap else: nil

    # Sends data to GPU
    render(
        camera.view, 
        camera.projection, 
        skybox,
        scene.drawables
    )

    # Swaps buffers
    swap()

