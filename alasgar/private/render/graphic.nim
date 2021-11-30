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
import shaders/deferred_frag
import shaders/deferred_vert
import frame_buffer
import depth_buffer

export opengl


const forwardV = staticRead("shaders/forward.vs")
const forwardF = staticRead("shaders/forward.fs")


type
    GraphicObj* = object
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
        depthMapSize: Vec2
        shaders*: seq[Shader]
        shadow*: tuple[
            view: Mat4,
            projection: Mat4,
            mvp: Mat4, 
            enabled: bool
        ]

    Graphic* = ref GraphicObj

proc `totalObjects`*(g: Graphic): int = g.totalObjects
proc `drawCalls`*(g: Graphic): int = g.drawCalls

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
        discard glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0)
    
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

    if deferred:
        result.shader = newShader(deferred_vert.source, deferred_frag.source, [])
    else:
        var fsource = forwardF
                .replace("$MAX_SPOTPOINT_LIGHTS$", &"{result.maxPointLights}")
                .replace("$MAX_POINT_LIGHTS$", &"{result.maxPointLights}")
                .replace("$MAX_DIRECT_LIGHTS$", &"{result.maxDirectLights}")
        var vsource = forwardV 
        result.shader = newShader(vsource, fsource, [])

    result.frameBuffer = newFrameBuffer(result.screenSize, deferred)
    result.depthBuffer = newDepthBuffer(depthMapSize)


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
                render(mesh, caddr(drawables[i + ix].world), caddr(drawables[i + ix].extra), 1)

        # Moves to next chunk
        inc(i, count)


proc renderFrameBuffer(g: Graphic, drawables: var seq[Drawable]) =
    use(g.frameBuffer, g.clearColor)

    # Resets render info
    g.totalObjects = 0
    g.totalBatches = 0
    g.drawCalls = 0

    var lastShader: Shader = nil
    var lastTexture: Texture = nil
    var lastNormal: Texture = nil

    var i = 0
    while i < len(drawables) and drawables[i].visible:
        var shader = if drawables[i].shader == nil: g.shader else: drawables[i].shader.instance
        var texture = if drawables[i].material != nil: drawables[i].material.texture else: nil
        var normal = if drawables[i].material != nil: drawables[i].material.normal else: nil
        var mesh = drawables[i].mesh.instance

        if shader != lastShader:
            lastShader = shader
            use(lastShader)
            if g.shadow.enabled:
                attach(g.depthBuffer)

        if texture != lastTexture:
            lastTexture = texture
            use(lastTexture, 1)
            shader["u_diffuse_texture"] = 1

        if normal != lastNormal:
            lastNormal = normal
            use(lastNormal, 2)
            shader["u_normal_texture"] = 2
            shader["u_normal_enabled"] = if lastNormal != nil: 1 else : 0


        # Limits instance count by max batch size
        var count = min(drawables[i].count, g.maxBatchSize)

        # Renders count amount of instances
        render(mesh, caddr(drawables[i].world), caddr(drawables[i].extra), count)

        inc(g.totalObjects, count)
        inc(g.drawCalls)
        inc(i, count)


proc render*(g: Graphic, drawables: var seq[Drawable]) =
    for shader in g.shaders:
        shader["u_depth_texture"] = 0
        shader["u_diffuse_texture"] = 1        
        shader["u_normal_texture"] = 2

    if g.shadow.enabled:
        renderDepthBuffer(g, drawables)
    renderFrameBuffer(g, drawables)

proc swap*(g: Graphic) =
    glViewport(0, 0, g.windowSize.iWidth, g.windowSize.iHeight)
    blit(g.frameBuffer)
    #blit(g.frameBuffer, g.depthBuffer.texture)
    glSwapWindow(g.window)


proc destroy*(g: Graphic) =
    if g.glContext != nil:
        glDeleteContext(g.glContext)
        g.glContext = nil

    if g.window != nil:
        destroy(g.window)
        g.window = nil


proc addShader*(g: Graphic, shader: Shader) =
    if shader != nil and not g.shaders.contains(shader):
        g.shaders.add(shader)

