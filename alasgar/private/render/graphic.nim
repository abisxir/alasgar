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
import depth_buffer
import skybox

export opengl

const forwardV = staticRead("shaders/forward.vs")
const forwardF = staticRead("shaders/simple.forward.fs")

type
    Graphic* = ref object
        vsync: bool
        clearColor*: chroma.Color
        screenSize*, windowSize*: Vec2
        window: WindowPtr
        glContext: GlContextPtr
        shader*: Shader
        maxBatchSize*: int
        maxPointLights*: int
        maxDirectLights*: int
        multiSample*: int
        totalObjects: int
        totalBatches: int
        drawCalls: int
        frameBuffer: FrameBuffer
        depthBuffer: DepthBuffer
        skybox: Skybox
        depthMapSize: Vec2
        shaders*: seq[Shader]
        shadow*: tuple[
            view: Mat4,
            projection: Mat4,
            mvp: Mat4, 
            enabled: bool
        ]

proc `totalObjects`*(g: Graphic): int = g.totalObjects
proc `drawCalls`*(g: Graphic): int = g.drawCalls

proc newSpatialShader*(g: Graphic, vertexSource: string="", fragmentSource: string=""): Shader =
    var 
        vsource: string
        fsource = forwardF
            .replace("$MAX_SPOTPOINT_LIGHTS$", &"{g.maxPointLights}")
            .replace("$MAX_POINT_LIGHTS$", &"{g.maxPointLights}")
            .replace("$MAX_DIRECT_LIGHTS$", &"{g.maxDirectLights}")
            
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

proc initOpenGL(g: Graphic, maxBatchSize, maxPointLights, maxDirectLights, multiSample: int) =
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
    g.maxPointLights = maxPointLights
    g.maxDirectLights = maxDirectLights
    g.multiSample = multiSample

    glEnable(GL_DEPTH_TEST)

proc newGraphic*(window: WindowPtr,
                 screenSize, windowSize: Vec2,
                 vsync: bool,
                 maxBatchSize, maxPointLights, maxDirectLights, multiSample: int,
                 deferred: bool=false,
                 depthMapSize: Vec2=vec2(1024, 1024)): Graphic =
    new(result)

    result.window = window
    result.vsync = vsync
    result.screenSize = screenSize
    result.windowSize = windowSize

    echo "* Initializing OpenGL..."

    initOpenGL(result, maxBatchSize, maxPointLights, maxDirectLights, multiSample)

    echo "* OpenGL initialized!"

    result.shader = newSpatialShader(result)
    result.frameBuffer = newFrameBuffer(result.screenSize, deferred)
    result.depthBuffer = newDepthBuffer(depthMapSize)
    result.skybox = newSkybox()


proc clear*(g: Graphic) =
    clear(g.shaders)
    add(g.shaders, g.shader)
    add(g.shaders, g.depthBuffer.shader)

proc renderDepthBuffer(g: Graphic, drawables: var seq[Drawable]) =
    use(g.depthBuffer)

    var i = 0
    while i < len(drawables) and drawables[i].visible:
        # Selects mesh
        var mesh = drawables[i].mesh.instance

        # Limits instance count by max batch size
        var count = min(drawables[i].count, g.maxBatchSize)

        for ix in 0..count - 1:
            if drawables[i + ix].material != nil and drawables[i + ix].material.castShadow:
                # Renders count amount of instances
                render(mesh, caddr(drawables[i + ix].modelPack), addr(drawables[i + ix].materialPack[0]), caddr(drawables[i + ix].spritePack), 1)

        # Moves to next chunk
        inc(i, count)


proc renderFrameBuffer(g: Graphic, drawables: var seq[Drawable]) =
    use(g.frameBuffer, g.clearColor)

    # Resets render info
    g.totalObjects = 0
    g.totalBatches = 0
    g.drawCalls = 0

    var lastShader: Shader = nil
    var lastAlbedo: Texture = nil
    var lastNormal: Texture = nil
    var lastMetallic: Texture = nil
    var lastRoughness: Texture = nil
    var lastAoMap: Texture = nil

    var i = 0
    while i < len(drawables) and drawables[i].visible:
        var shader = if drawables[i].shader == nil: g.shader else: drawables[i].shader.instance
        var albedo = if drawables[i].material != nil: drawables[i].material.albedoMap else: nil
        var normal = if drawables[i].material != nil: drawables[i].material.normalMap else: nil
        var metallic = if drawables[i].material != nil: drawables[i].material.metallicMap else: nil
        var roughness = if drawables[i].material != nil: drawables[i].material.roughnessMap else: nil
        var ao = if drawables[i].material != nil: drawables[i].material.aoMap else: nil
        var mesh = drawables[i].mesh.instance

        if shader != lastShader:
            lastShader = shader
            use(lastShader)
            if g.shadow.enabled:
                attach(g.depthBuffer, lastShader)

        if albedo != lastAlbedo:
            lastAlbedo = albedo
            #lastShader["u_albedo_map"] = 3
            use(lastAlbedo, 1)

        if normal != lastNormal:
            lastNormal = normal
            #lastShader["u_normal_map"] = 2
            use(lastNormal, 2)

        if metallic != lastMetallic:
            lastMetallic = metallic
            #lastShader["u_metallic_map"] = 1
            use(lastMetallic, 3)

        if roughness != lastRoughness:
            lastRoughness = roughness
            #lastShader["u_roughness_map"] = 4
            use(lastRoughness, 4)

        if ao != lastAoMap:
            lastAoMap = ao
            #lastShader["u_ao_map"] = 5
            use(lastAoMap, 5)

        # Limits instance count by max batch size
        var count = min(drawables[i].count, g.maxBatchSize)

        # Renders count amount of instances
        render(mesh, caddr(drawables[i].modelPack), addr(drawables[i].materialPack[0]), caddr(drawables[i].spritePack), count)

        inc(g.totalObjects, count)
        inc(g.drawCalls)
        inc(i, count)


proc render*(g: Graphic, view, projection: Mat4, cubemap: Texture, drawables: var seq[Drawable]) =
    # Renders shadow map if it is available
    if g.shadow.enabled:
        renderDepthBuffer(g, drawables)

    # Renders objects to framebuffer
    renderFrameBuffer(g, drawables)

    # Renders skybox to framebuffer
    if not isNil(cubemap):
        render(g.skybox, cubemap, view, projection)

proc swap*(g: Graphic) =
    glViewport(0, 0, g.windowSize.iWidth, g.windowSize.iHeight)
    blit(g.frameBuffer)
    glSwapWindow(g.window)


proc destroy*(g: Graphic) =
    if g.skybox != nil:
        destroy(g.skybox)
        g.skybox = nil

    if g.frameBuffer != nil:
        destroy(g.frameBuffer)
        g.frameBuffer = nil

    if g.depthBuffer != nil:
        destroy(g.depthBuffer)
        g.depthBuffer = nil

    if g.glContext != nil:
        glDeleteContext(g.glContext)
        g.glContext = nil

    if g.window != nil:
        destroy(g.window)
        g.window = nil

proc addShader*(g: Graphic, shader: Shader) =
    if shader != nil and not g.shaders.contains(shader):
        g.shaders.add(shader)

