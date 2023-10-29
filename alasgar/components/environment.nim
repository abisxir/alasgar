import ../core
import ../utils
import ../shaders/base
import ../system
import ../texture
import ../render/fb
import ../render/gpu
import ../shaders/ibl
import ../shaders/compile

#const iblFilterFS = staticRead("../shaders/_ibl-filter.fs")

# Forward declarations
#proc generateGGX(cubemap: Texture, sampleCount: int): Texture

type
    EnvironmentComponent* = ref object of Component
        backgroundColor*: Color
        ambientColor*: Color
        fogDensity*: float32
        fogGradient*: float32
        environmentMap*: Texture
        #ggxMap*: Texture
        #lutMap*: Texture
        environmentIntensity*: float32
        environmentBlurrity*: float32
        sampleCount*: int

    EnvironmentSystem* = ref object of System

func newEnvironmentComponent*(): EnvironmentComponent =
    new(result)
    result.environmentIntensity = 1.0
    result.environmentBlurrity = 0.0
    result.backgroundColor = color(0.0, 0.0, 0.0)
    result.sampleCount = 2048

## Sets the environment intensity
## @param env The environment component
## @param value The intensity value
func setEnvironmentIntensity*(env: EnvironmentComponent, value: float32) = env.environmentIntensity = value
func setEnvironmentBlurrity*(env: EnvironmentComponent, value: float32) = env.environmentBlurrity = value
func setSampleCount*(env: EnvironmentComponent, sampleCount: int) = env.sampleCount = sampleCount
func setAmbient*(env: EnvironmentComponent, c: Color, intense: float32) = env.ambientColor = color(c.r * intense, c.g * intense, c.b * intense)
func setFogDensity*(env: EnvironmentComponent, density: float32) = env.fogDensity = density
func setFogGradient*(env: EnvironmentComponent, gradient: float32) = env.fogGradient = gradient
func setBackground*(env: EnvironmentComponent, c: Color) = env.backgroundColor = c
func calculateMipMap(size: int): int = log2(size.float32).int + 1

proc panoramaToCubemap(inTexture: Texture, size: int): Texture =
    let 
        fb = newFramebuffer()
        shader = newCanvasShader(panoramaToCubemapFragment)
        texture = newCubeTexture(
            size,
            size,
            minFilter=GL_NEAREST_MIPMAP_LINEAR,
            magFilter=GL_LINEAR,
            levels=calculateMipMap(size)
        )
    
    use(shader)
    for i in 0..5:
        use(fb, texture, GL_TEXTURE_CUBE_MAP_POSITIVE_X.int + i, 0, size, size)
        use(shader, inTexture, "PANAROMA_MAP", 0)
        shader["FACE"] = i
        draw(fb)
    
    mipmap(texture)
    destroy(shader)
    destroy(fb)

    return texture

## Sets the given cubemap texture as skybox
proc setSkybox*(env: EnvironmentComponent, cubemap: Texture, size: int) =
    env.environmentMap = cubemap
    #env.ggxMap = generateGGX(cubemap, env.sampleCount)
    #env.lutMap = generateLUT(cubemap, env.sampleCount)

## Loads the given six images and sets it as skybox
proc setSkybox*(env: EnvironmentComponent, px, nx, py, ny, pz, nz: string, size: int) = 
    let cubeTexture = newCubeTexture(
        px, 
        nx, 
        py, 
        ny, 
        pz, 
        nz
    )
    setSkybox(
        env, 
        cubeTexture,
        size
    )

## Loads the given panaroma image and sets it as skybox
proc setSkybox*(env: EnvironmentComponent, url: string, size: int) = 
    let 
        # Loads the given panaroma into a texture
        inTexture = newTexture(url)
        # Converts panaroma texture to cubemap
        cubemap = panoramaToCubemap(inTexture, size)
    # Destroys the created texture
    destroy(inTexture)
    # Sets the created cubemap from panaroma image as skybox
    setSkybox(env, cubemap, size)

# System implementation
proc newEnvironmentSystem*(): EnvironmentSystem =
    new(result)
    result.name = "Environment System"

method process*(sys: EnvironmentSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) =
    {.warning[LockLevel]:off.}
    if scene.root != nil and hasComponent[EnvironmentComponent](scene):
        let env = first[EnvironmentComponent](scene)
        
        graphics.context.environmentIntensity = env.environmentIntensity
        graphics.context.environmentBlurrity = env.environmentBlurrity

        for shader in graphics.context.shaders:
            use(shader)

            # Sets scene clear color
            graphics.context.clearColor = env.backgroundColor
            shader["ENVIRONMENT.BACKGROUND_COLOR"] = env.backgroundColor

            # Sets scene ambient color
            shader["ENVIRONMENT.AMBIENT_COLOR"] = env.ambientColor.vec3

            # Sets environment maps
            if not isNil(env.environmentMap):
                use(shader, env.environmentMap, "SKYBOX_MAP", 7)
                shader["ENVIRONMENT.MIP_COUNT"] = env.environmentMap.levels.float32
                shader["ENVIRONMENT.INTENSITY"] = env.environmentIntensity
                shader["ENVIRONMENT.HAS_ENV_MAP"] = 1
            else:
                shader["ENVIRONMENT.HAS_ENV_MAP"] = 0

            if env.fogDensity > 0.0:
                shader["ENVIRONMENT.FOG_DENSITY"] = env.fogDensity
                shader["ENVIRONMENT.FOG_GRADIENT"] = env.fogGradient
            else:
                shader["ENVIRONMENT.FOG_DENSITY"] = 0.0

#[
proc filter(cubemap: Texture, 
            fb: FrameBuffer,
            target: Texture,
            level: int,
            distribution: int,
            sampleCount: int,
            lodBias: float32) =
    let 
        shader = newCanvasShader(iblFilterFS)
        roughness = level.float32 / (target.levels.float32 - 1.0)
        size = cubemap.width
        currentTextureSize = size shr level
    
    for i in 0..5:
        use(fb, target, GL_TEXTURE_CUBE_MAP_POSITIVE_X.int + i, level, currentTextureSize, currentTextureSize)       
        use(shader)
        use(shader, cubemap, "u_cubemap", 0)

        shader["u_roughness"] = roughness
        shader["u_sample_count"] = sampleCount
        shader["u_width"] = size
        shader["u_lod_bias"] = lodBias
        shader["u_distribution"] = distribution
        shader["u_current_face"] = i
        shader["u_is_generating_lut"] = 0.int

        draw(fb)

    destroy(shader)


proc generateGGX(cubemap: Texture, sampleCount: int): Texture =
    let 
        fb = newFramebuffer()
        size: int = cubemap.width
        texture = newCubeTexture(
            size, 
            size, 
            minFilter=GL_LINEAR, 
            magFilter=GL_LINEAR, 
            levels=calculateMipMap(size)
        )

    mipmap(texture)

    for level in 0..texture.levels - 1:
        filter(
            cubemap=cubemap, 
            fb=fb, 
            target=texture, 
            level=level, 
            distribution=1, 
            sampleCount=sampleCount, 
            lodBias=0.0
        )

    destroy(fb)

    result = texture

proc generateLUT(cubemap: Texture, sampleCount: int): Texture =
    let 
        shader = newShader(fullscreenVS, iblFilterFS, [])
        fb = newFramebuffer()
        texture = newTexture2D(
            cubemap.width, 
            cubemap.height,
            minFilter=GL_LINEAR, 
            magFilter=GL_LINEAR,
            levels=1
        )

    allocate(texture)
    use(fb, texture, GL_TEXTURE_2D.int, 0, cubemap.width, cubemap.height)
    use(shader)
    use(shader, cubemap, "u_cubemap", 0)

    shader["u_roughness"] = 0.0
    shader["u_sample_count"] = sampleCount
    shader["u_width"] = 0
    shader["u_lod_bias"] = 0.0
    shader["u_distribution"] = 1
    shader["u_current_face"] = 0
    shader["u_is_generating_lut"] = 1.int

    draw(fb)

    destroy(shader)
    destroy(fb)

    result = texture

]#