import ../core
import ../utils
import ../shader
import ../system
import ../texture
import ../framebuffer
import times

const fullscreenVS = staticRead("../render/shaders/fullscreen.vs")
const panaromaToCubemapFS = staticRead("../render/shaders/panaroma-to-cube-map.fs")
const iblFilterFS = staticRead("../render/shaders/ibl-filter.fs")

const fxaaReduceMinDefault: float32 = 1.0 / 128.0
const fxaaReduceMulDefault: float32 = 1.0 / 8.0
const fxaaSpanMaxDefault: float32 = 8.0

type
    EnvironmentComponent* = ref object of Component
        backgroundColor*: Color
        ambientColor*: Color
        fogColor*: Color
        fogDensity*: float32
        fogGradient*: float32
        fogEnabled*: bool
        lutMap*: Texture
        environmentMap*: Texture
        environmentIntensity*: float32
        ggxMap*: Texture
        fxaaEnabled*: bool
        fxaaSpanMax*: float
        fxaaReduceMul*: float
        fxaaReduceMin*: float

    EnvironmentSystem* = ref object of System

func newEnvironmentComponent*(): EnvironmentComponent =
    new(result)
    result.environmentIntensity = 1.0

func setAmbient*(e: EnvironmentComponent, c: Color, intense: float32) =
    e.ambientColor = color(c.r * intense, c.g * intense, c.b * intense)

func enableFog*(e: EnvironmentComponent, color: Color, density, gradient: float32) =
    e.fogEnabled = true
    e.fogColor = color
    e.fogDensity = density
    e.fogGradient = gradient

func enableFXAA*(e: EnvironmentComponent, 
                 fxaaSpanMax=fxaaSpanMaxDefault,
                 fxaaReduceMul=fxaaReduceMulDefault,
                 fxaaReduceMin=fxaaReduceMinDefault) =
    e.fxaaEnabled = true
    e.fxaaSpanMax = fxaaSpanMax
    e.fxaaReduceMul = fxaaReduceMul
    e.fxaaReduceMin = fxaaReduceMin

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
    let shader = newShader(fullscreenVS, iblFilterFS, [])
    let roughness = level.float32 / (target.levels.float32 - 1.0)
    let size = cubemap.width
    let currentTextureSize = size shr level
    
    for i in 0..5:
        use(fb)
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, (GL_TEXTURE_CUBE_MAP_POSITIVE_X.int + i).GLenum, target.id, level.GLint)
        glBindTexture(GL_TEXTURE_CUBE_MAP, target.id)        
        glViewport(0, 0, currentTextureSize.GLsizei, currentTextureSize.GLsizei)
        glClearColor(1, 0, 0, 0)
        glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
        
        use(shader)
        use(cubemap, 0)

        shader["u_roughness"] = roughness
        shader["u_sample_count"] = sampleCount
        shader["u_width"] = size
        shader["u_lod_bias"] = lodBias
        shader["u_distribution"] = distribution
        shader["u_current_face"] = i
        shader["u_is_generating_lut"] = 0.int

        glDrawArrays(GL_TRIANGLES, 0, 3)

    destroy(shader)

proc panoramaToCubemap(inTexture: Texture, size: int): Texture =
    let fb = newFramebuffer()
    let shader = newShader(fullscreenVS, panaromaToCubemapFS, [])
    result = newCubeTexture(size, size, minFilter=GL_LINEAR, magFilter=GL_LINEAR, levels=calculateMipMap(size))
    use(shader)
    for i in 0..5:
        use(fb)
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, (GL_TEXTURE_CUBE_MAP_POSITIVE_X.int + i).GLenum, result.id, 0)
        glBindTexture(GL_TEXTURE_CUBE_MAP, result.id)        
        glViewport(0, 0, size.GLsizei, size.GLsizei)
        glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
        use(inTexture, 0)
        shader["u_current_face"] = i
        glDrawArrays(GL_TRIANGLES, 0, 3)
    
    mipmap(result)
    destroy(shader)
    destroy(fb)

proc generateGGX(cubemap: Texture): Texture =
    let fb = newFramebuffer()
    let size: int = cubemap.width

    result = newCubeTexture(
        size, 
        size, 
        minFilter=GL_LINEAR, 
        magFilter=GL_LINEAR, 
        levels=calculateMipMap(size)
    )
    mipmap(result)

    for level in 0..result.levels - 1:
        filter(
            cubemap=cubemap, 
            fb=fb, 
            target=result, 
            level=level, 
            distribution=1, 
            sampleCount=1024, 
            lodBias=0.0
        )

    destroy(fb)

proc generateLUT(cubemap: Texture): Texture =
    let shader = newShader(fullscreenVS, iblFilterFS, [])
    let fb = newFramebuffer()

    result = newTexture2D(
        cubemap.width, 
        cubemap.height,
        minFilter=GL_LINEAR, 
        magFilter=GL_LINEAR,
        levels=1
    )
    allocate(result)

    use(fb)
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, result.id, 0.GLint)
    glBindTexture(GL_TEXTURE_2D, result.id)        
    glViewport(0, 0, cubemap.width.GLsizei, cubemap.height.GLsizei)
    glClearColor(1, 0, 0, 0)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
    
    use(shader)
    use(cubemap, 0)

    shader["u_roughness"] = 0.0
    shader["u_sample_count"] = 512
    shader["u_width"] = 0
    shader["u_lod_bias"] = 0.0
    shader["u_distribution"] = 1
    shader["u_current_face"] = 0
    shader["u_is_generating_lut"] = 1.int

    glDrawArrays(GL_TRIANGLES, 0, 3)

    destroy(shader)
    destroy(fb)


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
    # Loads the given panaroma into a texture
    let inTexture = newTexture(url)

    # Converts panaroma texture to cubemap
    let cubemap = panoramaToCubemap(inTexture, size)

    # Destroys the given texture
    destroy(inTexture)

    # Sets cubemap as skybox
    setSkybox(env, cubemap, size)

#[
    let specularMapShader = newComputeShader(specularMapCS)
    let filteredTexture = newTexture(
        target=GL_TEXTURE_CUBE_MAP,
        width=size, 
        height=size, 
        internalFormat=GL_RGBA16F,
        format=GL_RGBA,
        dataType=cGL_FLOAT,
        levels=1
    )
    copy(rawTexture, filteredTexture)

    use(specularMapShader)
    use(rawTexture, 0)

    let deltaRoughness: float32 = 1.0 / max(float32(filteredTexture.levels - 1), 1.0)
    var step = size / 2
    for level in 1..filteredTexture.levels:
        let numGroups = max(1, step / 32)
        useForOutput(filteredTexture, 0, level)
        specularMapShader["roughness"] = level.float32 * deltaRoughness
        compute(numGroups.int, numGroups.int, 6)
        step = step / 2

    destroy(rawTexture)
    destroy(specularMapShader)

    env.skybox = filteredTexture
    let elapsed = between(start, now())
]#

# System implementation
proc newEnvironmentSystem*(): EnvironmentSystem =
    new(result)
    result.name = "Environment System"

method process*(sys: EnvironmentSystem, scene: Scene, input: Input, delta: float32, frames: float32, age: float32) =
    if scene.root != nil and hasComponent[EnvironmentComponent](scene):
        let env = first[EnvironmentComponent](scene)
        
        sys.graphic.context.environmentIntensity = env.environmentIntensity
        sys.graphic.context.fxaaEnabled = env.fxaaEnabled
        sys.graphic.context.fxaaSpanMax = env.fxaaSpanMax
        sys.graphic.context.fxaaReduceMin = env.fxaaReduceMin
        sys.graphic.context.fxaaReduceMul = env.fxaaReduceMul

        for shader in sys.graphic.context.shaders:
            use(shader)

            # Sets scene clear color
            sys.graphic.context.clearColor = env.backgroundColor
            shader["env.clear_color"] = env.ambientColor.vec3

            # Sets scene ambient color
            shader["env.ambient_color"] = env.ambientColor.vec3

            # Sets environment maps
            if not isNil(env.environmentMap):
                use(env.ggxMap, 6)
                shader["env.mip_count"] = env.environmentMap.levels.float32

            if env.fogEnabled:
                shader["env.fog_enabled"] = 1
                shader["env.fog_color"] = env.fogColor
                shader["env.fog_density"] = env.fogDensity
                shader["env.fog_gradient"] = env.fogGradient
            else:
                shader["env.fog_enabled"] = 0


