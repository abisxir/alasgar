import strutils
import strformat

import sdl2
import chroma
import ../ports/opengl

import ../utils
import ../shader
import ../texture
import ../mesh
import ../core
import frame_buffer
import shadow
import skybox
import context

export opengl, context

const forwardV = staticRead("shaders/forward.vs")
const forwardF = staticRead("shaders/forward.fs")

type
    Graphic* = ref object
        screenSize*, windowSize*: Vec2
        maxBatchSize*: int
        maxLights*: int
        multiSample*: int
        shader: Shader
        vsync: bool
        window: WindowPtr
        glContext: GlContextPtr
        totalObjects: int
        totalBatches: int
        drawCalls: int
        frameBuffer: FrameBuffer
        skybox: Skybox
        shadow: Shadow
        context*: GraphicContext

proc `totalObjects`*(g: Graphic): int = g.totalObjects
proc `drawCalls`*(g: Graphic): int = g.drawCalls

proc newSpatialShader*(g: Graphic, vertexSource: string="", fragmentSource: string=""): Shader =
    var 
        vsource: string
        fsource = forwardF.replace("$MAX_LIGHTS$", &"{g.maxLights}")
            
    if isEmptyOrWhitespace(fragmentSource):
        fsource = fsource
            .replace("$MAIN_FUNCTION$", "")
            .replace("$MAIN_FUNCTION_CALL$", "")
    else:
        fsource = fsource
            .replace("$MAIN_FUNCTION$", fragmentSource)
            .replace("$MAIN_FUNCTION_CALL$", "fragment();")

    if isEmptyOrWhitespace(vertexSource):
        vsource = forwardV
            .replace("$MAIN_FUNCTION$", "")
            .replace("$MAIN_FUNCTION_CALL$", "")
    else:
        vsource = forwardV
            .replace("$MAIN_FUNCTION$", vertexSource)
            .replace("$MAIN_FUNCTION_CALL$", "vertex();")

    result = newShader(vsource, fsource, [])

proc initOpenGL(g: Graphic, maxBatchSize, maxLights, multiSample: int) =
    # Initialize opengl context
    discard glSetAttribute(SDL_GL_SHARE_WITH_CURRENT_CONTEXT, 1)
    when defined(macosx):
        discard glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE)
        discard glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4)
        discard glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1)
        discard glSetAttribute(SDL_GL_RED_SIZE, 8)
        discard glSetAttribute(SDL_GL_GREEN_SIZE, 8)
        discard glSetAttribute(SDL_GL_BLUE_SIZE, 8)
        discard glSetAttribute(SDL_GL_ALPHA_SIZE, 8)
        discard glSetAttribute(SDL_GL_STENCIL_SIZE, 8)
        #discard glSetAttribute(SDL_GL_DEPTH_SIZE, 32)
    else:
        discard glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES)
        discard glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3)
        discard glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1)
    
    discard glSetAttribute(SDL_GL_DOUBLEBUFFER, 1)
    #discard glSetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1)
    #discard glSetAttribute(SDL_GL_MULTISAMPLESAMPLES, multiSample)
    
    #discard glSetAttribute(SDL_GL_DEPTH_SIZE, 24)

    # Creates opengl context
    g.glContext = glCreateContext(g.window)

    # Checks that opengl context has created
    if g.glContext == nil:
        quit "Could not create context!"

    # Sets vsync to off, if required
    if not g.vsync:
        discard glSetSwapInterval(0.cint)

    # Activates opengl context
    discard glMakeCurrent(g.window, g.glContext)

    # Loads opengl es
    discard gladLoadGLES2(glGetProcAddress)

    # Sets batch size
    g.maxBatchSize = maxBatchSize
    g.maxLights = maxLights
    g.multiSample = multiSample

    glEnable(GL_DEPTH_TEST)

proc newGraphic*(window: WindowPtr,
                 screenSize, windowSize: Vec2,
                 vsync: bool,
                 maxBatchSize, maxLights, multiSample: int,
                 deferred: bool=false): Graphic =
    new(result)

    result.window = window
    result.vsync = vsync
    result.screenSize = screenSize
    result.windowSize = windowSize

    echo "* Initializing OpenGL..."

    initOpenGL(result, maxBatchSize, maxLights, multiSample)

    echo "* OpenGL initialized!"

    result.shader = newSpatialShader(result)
    result.frameBuffer = newFrameBuffer(result.screenSize, deferred)
    result.skybox = newSkybox()
    result.shadow = newShadow()

proc clear*(g: Graphic) =
    g.context.maxBatchSize = g.maxBatchSize
    clear(g.context.shaders)
    clear(g.context.shadowCasters)
    add(g.context.shaders, g.shader)

proc renderFrameBuffer(g: Graphic, view, projection: Mat4, cubemap: Texture, drawables: var seq[Drawable]) =
    use(g.frameBuffer, g.context.clearColor)

    if not isNil(cubemap):
        render(g.skybox, cubemap, view, projection, g.context.environmentIntensity)

    # Resets render info
    g.totalObjects = 0
    g.totalBatches = 0
    g.drawCalls = 0

    var 
        lastShader: Shader = nil
        lastAlbedo: Texture = nil
        lastNormal: Texture = nil
        lastMetallic: Texture = nil
        lastRoughness: Texture = nil
        lastAoMap: Texture = nil
        lastEmissiveMap: Texture = nil

    var i = 0
    while i < len(drawables) and drawables[i].visible:
        var 
            shader = if drawables[i].shader == nil: g.shader else: drawables[i].shader.instance
            albedo = if drawables[i].material != nil: drawables[i].material.albedoMap else: nil
            normal = if drawables[i].material != nil: drawables[i].material.normalMap else: nil
            metallic = if drawables[i].material != nil: drawables[i].material.metallicMap else: nil
            roughness = if drawables[i].material != nil: drawables[i].material.roughnessMap else: nil
            ao = if drawables[i].material != nil: drawables[i].material.aoMap else: nil
            emissive = if drawables[i].material != nil: drawables[i].material.emissiveMap else: nil
            mesh = drawables[i].mesh.instance

        if shader != lastShader:
            lastShader = shader
            use(lastShader)
            #if g.shadow.enabled:
            #    attach(g.depthBuffer, lastShader)

        if albedo != lastAlbedo:
            lastAlbedo = albedo
            #lastShader["u_albedo_map"] = 3
            use(lastAlbedo, 0)

        if normal != lastNormal:
            lastNormal = normal
            #lastShader["u_normal_map"] = 2
            use(lastNormal, 1)

        if metallic != lastMetallic:
            lastMetallic = metallic
            #lastShader["u_metallic_map"] = 1
            use(lastMetallic, 2)

        if roughness != lastRoughness:
            lastRoughness = roughness
            #lastShader["u_roughness_map"] = 4
            use(lastRoughness, 3)

        if ao != lastAoMap:
            lastAoMap = ao
            #lastShader["u_ao_map"] = 5
            use(lastAoMap, 4)

        if emissive != lastEmissiveMap:
            lastEmissiveMap = emissive
            #lastShader["u_emissive_map"] = 6
            use(lastEmissiveMap, 5)

        # Limits instance count by max batch size
        var count = min(drawables[i].count, g.maxBatchSize)

        # Renders count amount of instances
        render(mesh, caddr(drawables[i].modelPack), addr(drawables[i].materialPack[0]), caddr(drawables[i].spritePack), count)

        inc(g.totalObjects, count)
        inc(g.drawCalls)
        inc(i, count)


proc render*(g: Graphic, view, projection: Mat4, cubemap: Texture, drawables: var seq[Drawable]) =
    # If there is shadow casters processes them
    if len(g.context.shadowCasters) > 0:
        process(g.shadow, g.context, drawables)

    # Renders objects to framebuffer
    renderFrameBuffer(g, view, projection, cubemap, drawables)

proc swap*(g: Graphic) =
    glViewport(0, 0, g.windowSize.iWidth, g.windowSize.iHeight)
    blit(g.frameBuffer, g.context)
    glSwapWindow(g.window)

proc destroy*(g: Graphic) =
    if g.skybox != nil:
        destroy(g.skybox)
        g.skybox = nil

    if g.frameBuffer != nil:
        destroy(g.frameBuffer)
        g.frameBuffer = nil

    #if g.depthBuffer != nil:
    #    destroy(g.depthBuffer)
    #    g.depthBuffer = nil

    if g.glContext != nil:
        glDeleteContext(g.glContext)
        g.glContext = nil

    if g.window != nil:
        destroy(g.window)
        g.window = nil


