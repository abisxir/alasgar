import ../core
import ../system
import ../components/camera
import ../render/gpu
import ../shaders/base

type
    RenderSystem* = ref object of System

proc newRenderSystem*(): RenderSystem =
    new(result)
    result.name = "Render System"

proc prepareShaders(scene: Scene) =
    graphics.context.environmentIntensity = scene.environmentIntensity
    graphics.context.environmentBlurrity = scene.environmentBlurrity

    for shader in graphics.context.shaders:
        use(shader)

        if hasUniform(shader, "SKIN_MAP"):
            shader["SKIN_MAP"] = 0
        if hasUniform(shader, "ALBEDO_MAP"):
            shader["ALBEDO_MAP"] = 1
        if hasUniform(shader, "NORMAL_MAP"):
            shader["NORMAL_MAP"] = 2
        if hasUniform(shader, "METALLIC_MAP"):
            shader["METALLIC_MAP"] = 3
        if hasUniform(shader, "ROUGHNESS_MAP"):
            shader["ROUGHNESS_MAP"] = 4
        if hasUniform(shader, "AO_MAP"):
            shader["AO_MAP"] = 5
        if hasUniform(shader, "EMISSIVE_MAP"):
            shader["EMISSIVE_MAP"] = 6
        if hasUniform(shader, "SKYBOX_MAP"):
            shader["SKYBOX_MAP"] = 7
        if hasUniform(shader, "DEPTH_MAPS"):
            shader["DEPTH_MAPS"] = 8
        if hasUniform(shader, "DEPTH_CUBE_MAPS"):
            shader["DEPTH_CUBE_MAPS"] = 9
        
        # Sets scene clear color
        graphics.context.clearColor = scene.background
        shader["ENVIRONMENT.BACKGROUND_COLOR"] = scene.background

        # Sets scene ambient color
        shader["ENVIRONMENT.AMBIENT_COLOR"] = scene.ambient.vec3

        # Sets environment maps
        if not isNil(scene.environmentMap):
            use(shader, scene.environmentMap, "SKYBOX_MAP", 7)
            shader["ENVIRONMENT.MIP_COUNT"] = scene.environmentMap.levels.float32
            shader["ENVIRONMENT.INTENSITY"] = scene.environmentIntensity
            shader["ENVIRONMENT.HAS_ENV_MAP"] = 1
        else:
            shader["ENVIRONMENT.HAS_ENV_MAP"] = 0

        if scene.fogDensity > 0.0:
            shader["ENVIRONMENT.FOG_DENSITY"] = scene.fogDensity
            shader["ENVIRONMENT.MIN_FOG_DISTANCE"] = scene.minFogDistance
        else:
            shader["ENVIRONMENT.FOG_DENSITY"] = 0.0


method process*(sys: RenderSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) =  
    let 
        # Gets active camera, it is needed for getting view and projection matrix
        camera = scene.activeCamera

    prepareShaders(scene)

    # Sends data to GPU
    render(
        camera.view, 
        camera.projection, 
        scene.environmentMap,
        scene.drawables
    )

    # Swaps buffers
    swap()

