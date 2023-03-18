
import sdl2
import ../ports/opengl

import ../utils
import ../shader
import ../texture
import ../mesh
import ../core
import fb
import shadow
import skybox
import context

export opengl, context

type
    Graphic* = ref object
        screenSize*, windowSize*: Vec2
        shader: Shader
        blitShader: Shader
        vsync: bool
        window: WindowPtr
        glContext: GlContextPtr
        totalObjects: int
        totalBatches: int
        drawCalls: int
        fb: FrameBuffer
        skybox: Skybox
        shadow: Shadow
        effectsFrameBuffer: FrameBuffer
        effectsTexture: Texture 
        context*: GraphicContext

var
    maxBatchSize = 2048

proc `totalObjects`*(g: Graphic): int = g.totalObjects
proc `drawCalls`*(g: Graphic): int = g.drawCalls

proc initOpenGL(g: Graphic) =
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
    else:
        discard glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES)
        discard glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3)
        discard glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1)
    
    discard glSetAttribute(SDL_GL_DOUBLEBUFFER, 1)

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

    glEnable(GL_DEPTH_TEST)

proc newGraphic*(window: WindowPtr,
                 screenSize, windowSize: Vec2,
                 vsync: bool): Graphic =
    new(result)

    result.window = window
    result.vsync = vsync
    result.screenSize = screenSize
    result.windowSize = windowSize

    echo "* Initializing OpenGL..."

    initOpenGL(result)

    echo "* OpenGL initialized!"

    result.shader = newSpatialShader()
    result.blitShader = newCanvasShader()
    result.fb = newRenderBuffer(result.screenSize)
    result.skybox = newSkybox()
    result.shadow = newShadow()

proc clear*(g: Graphic) =
    clear(g.context.shaders)
    clear(g.context.shadowCasters)
    clear(g.context.effects)
    add(g.context.shaders, g.shader)

proc renderToFrameBuffer(g: Graphic, view, projection: Mat4, cubemap: Texture, drawables: var seq[Drawable]) =
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
        var count = min(drawables[i].count, maxBatchSize)

        # Renders count amount of instances
        render(
            mesh, 
            caddr(drawables[i].modelPack), 
            addr(drawables[i].materialPack[0]), 
            caddr(drawables[i].spritePack), 
            caddr(drawables[i].skinPack), 
            count
        )

        inc(g.totalObjects, count)
        inc(g.drawCalls)
        inc(i, count)
    


proc render*(g: Graphic, view, projection: Mat4, cubemap: Texture, drawables: var seq[Drawable]) =
    # If there is shadow casters processes them
    if len(g.context.shadowCasters) > 0:
        process(g.shadow, g.context, drawables)

    # Binds to framebuffer
    use(g.fb, g.context.clearColor)

    # Renders objects to framebuffer
    renderToFrameBuffer(g, view, projection, cubemap, drawables)

    # Detachs from framebuffer
    detach(g.fb)

proc applyEffects(g: Graphic): Texture =
    if len(g.context.effects) > 0:
        if isNil(g.effectsFrameBuffer):
            g.effectsFrameBuffer = newFramebuffer()
            g.effectsTexture = newTexture2D(g.screenSize.iWidth, g.screenSize.iHeight, levels=1)
            allocate(g.effectsTexture)
        var 
            source = g.effectsTexture
            target = g.fb.color
        for shader in g.context.effects:
            swap(source, target)
            use(g.effectsFrameBuffer, target, GL_TEXTURE_2D.int, 0, g.screenSize.iWidth, g.screenSize.iHeight)
            use(shader)
            use(source, 4)
            use(g.fb.normal, 5)
            use(g.fb.depth, 6)
            draw(g.effectsFrameBuffer)
        result = target
    else:
        result = g.fb.color            


proc swap*(g: Graphic) =
    let blitTexture = applyEffects(g)
    glBindRenderbuffer(GL_RENDERBUFFER, 0)
    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    glViewport(0, 0, g.windowSize.iWidth, g.windowSize.iHeight)
    #glEnable(GL_BLEND)
    #glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glDisable(GL_DEPTH_TEST)
    glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT)

    use(g.blitShader)
    use(blitTexture, 4)
    use(g.fb.normal, 5)
    use(g.fb.normal, 6)
    glDrawArrays(GL_TRIANGLES, 0, 3)
   
    glSwapWindow(g.window)

proc destroy*(g: Graphic) =
    destroy(g.skybox)
    g.skybox = nil

    destroy(g.fb)
    g.fb = nil

    destroy(g.shadow)
    g.shadow = nil

    if g.glContext != nil:
        glDeleteContext(g.glContext)
        g.glContext = nil

    if g.window != nil:
        destroy(g.window)
        g.window = nil


