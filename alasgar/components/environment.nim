import times

import ../core
import ../utils
import ../shaders/base
import ../system
import ../texture
import ../render/fb
import ../render/gpu
import ../shaders/effect
import ../shaders/ibl
import ../shaders/compile

const iblFilterFS = staticRead("../shaders/ibl-filter.fs")
const fullscreenVS = toGLSL(effectVertex)
const panaromaToCubemapFS = toGLSL(panoramaToCubemapFragment)

type
    EnvironmentComponent* = ref object of Component
        backgroundColor*: Color
        ambientColor*: Color
        fogDensity*: float32
        fogGradient*: float32
        lutMap*: Texture
        environmentMap*: Texture
        environmentIntensity*: float32
        ggxMap*: Texture

    EnvironmentSystem* = ref object of System

#proc attach(fb: FrameBuffer, texture: Texture, unit: int, size: int, level: int) =
#    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, unit.GLenum, texture.id, level.GLint)
#    attach(texture)
#    glViewport(0, 0, size.GLsizei, size.GLsizei)
#    #glClearColor(1, 0, 0, 0)
#    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)


func newEnvironmentComponent*(): EnvironmentComponent =
    new(result)
    result.environmentIntensity = 1.0
    result.backgroundColor = color(0.12, 0.12, 0.12)

func setEnvironmentIntensivity*(e: EnvironmentComponent, value: float32) =
    e.environmentIntensity = value

func setAmbient*(e: EnvironmentComponent, c: Color, intense: float32) =
    e.ambientColor = color(c.r * intense, c.g * intense, c.b * intense)

func enableFog*(e: EnvironmentComponent, density, gradient: float32) =
    e.fogDensity = density
    e.fogGradient = gradient

func setBackground*(env: EnvironmentComponent, c: Color) =
    env.backgroundColor = c

func calculateMipMap(size: int): int = log2(size.float32).int - 3

proc filter(cubemap: Texture, 
            fb: FrameBuffer,
            target: Texture,
            level: int,
            distribution: int,
            sampleCount: int,
            lodBias: float32) =
    let 
        shader = newShader(fullscreenVS, iblFilterFS, [])
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

proc panoramaToCubemap(inTexture: Texture, size: int): Texture =
    let 
        fb = newFramebuffer()
        shader = newShader(fullscreenVS, panaromaToCubemapFS, [])
        texture = newCubeTexture(size, size, minFilter=GL_LINEAR, magFilter=GL_LINEAR, levels=calculateMipMap(size))

    use(shader)
    for i in 0..5:
        use(fb, texture, GL_TEXTURE_CUBE_MAP_POSITIVE_X.int + i, 0, size, size)
        use(shader, inTexture, "u_panorama", 0)
        shader["u_current_face"] = i
        draw(fb)
    
    mipmap(texture)
    destroy(shader)
    destroy(fb)

    return texture

proc generateGGX(cubemap: Texture): Texture =
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
            sampleCount=1024, 
            lodBias=0.0
        )

    destroy(fb)

    result = texture

proc generateLUT(cubemap: Texture): Texture =
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
    shader["u_sample_count"] = 512
    shader["u_width"] = 0
    shader["u_lod_bias"] = 0.0
    shader["u_distribution"] = 1
    shader["u_current_face"] = 0
    shader["u_is_generating_lut"] = 1.int

    draw(fb)

    destroy(shader)
    destroy(fb)

    result = texture


proc setSkybox*(env: EnvironmentComponent, cubemap: Texture, size: int) =
    let start = now()

    env.environmentMap = cubemap
    env.ggxMap = generateGGX(cubemap)
    env.lutMap = generateLUT(cubemap)

    let elapsed = between(start, now())
    echo "* Skybox compute done in:", elapsed

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

proc setSkybox*(env: EnvironmentComponent, url: string, size: int) = 
    let 
        # Loads the given panaroma into a texture
        inTexture = newTexture(url)
        # Converts panaroma texture to cubemap
        cubemap = panoramaToCubemap(inTexture, size)

    # Destroys the given texture
    destroy(inTexture)

    # Sets cubemap as skybox
    setSkybox(env, cubemap, size)

# System implementation
proc newEnvironmentSystem*(): EnvironmentSystem =
    new(result)
    result.name = "Environment System"

method process*(sys: EnvironmentSystem, scene: Scene, input: Input, delta: float32, frames: float32, age: float32) =
    if scene.root != nil and hasComponent[EnvironmentComponent](scene):
        let env = first[EnvironmentComponent](scene)
        
        graphics.context.environmentIntensity = env.environmentIntensity

        for shader in graphics.context.shaders:
            use(shader)

            # Sets scene clear color
            graphics.context.clearColor = env.backgroundColor
            shader["ENV.BACKGROUND_COLOR"] = env.backgroundColor

            # Sets scene ambient color
            shader["ENV.AMBIENT_COLOR"] = env.ambientColor.vec3

            # Sets environment maps
            if not isNil(env.environmentMap):
                use(shader, env.ggxMap, "GGX_MAP", 7)
                shader["ENV.MIP_COUNT"] = env.environmentMap.levels.float32
                shader["ENV.HAS_ENV_MAP"] = 1
            else:
                shader["ENV.HAS_ENV_MAP"] = 0

            if env.fogDensity > 0.0:
                shader["ENV.FOG_DENSITY"] = env.fogDensity
                shader["ENV.FOG_GRADIENT"] = env.fogGradient
            else:
                shader["ENV.FOG_DENSITY"] = 0.0


