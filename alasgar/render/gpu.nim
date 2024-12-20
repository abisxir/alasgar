
import ../ports/sdl2
import ../ports/opengl

import ../utils
import ../shaders/base
import ../texture
import ../mesh
import ../core
import fb
import shadow
import skybox
import context

export opengl, context

type
    Graphics* = object
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
        screenSize: Vec2
        windowSize*: Vec2
        context*: GraphicsContext
        emptyTexture: Texture
        skinTexture*: Texture

var
    graphics*: Graphics

# As long as glContext is nil, graphics is not initialized
graphics.glContext = nil

proc initGraphics*(window: WindowPtr,
                   screenSize, windowSize: Vec2,
                   vsync: bool) =
    if graphics.glContext == nil:
        graphics.window = window
        graphics.vsync = vsync
        graphics.screenSize = screenSize
        graphics.windowSize = windowSize
        graphics.glContext = createOpenGLContext(window)
        graphics.emptyTexture = newTexture(COLOR_BLACK)
        graphics.skinTexture = newTexture2D(settings.maxSkinTextureSize, settings.maxSkinTextureSize, internalFormat=GL_RGBA32F)
        allocate(graphics.skinTexture)
        graphics.shader = newSpatialShader()
        graphics.blitShader = newCanvasShader()
        graphics.fb = newRenderBuffer(graphics.screenSize)
        echo "* Framebuffer initialized!"
        graphics.skybox = newSkybox()
        echo "* Skybox initialized!"
        graphics.shadow = newShadow()
        echo "* Shadow initialized!"

        # Sets vsync to off, if required
        when not defined(emscripten):
            if not graphics.vsync:
                discard glSetSwapInterval(0.cint)


        echo "* Graphics initialized!"

proc resizeGraphics*(windowSize: Vec2) =
    graphics.windowSize = windowSize
    if not settings.keepRatio:
        if settings.screenSize.x == 0 and settings.screenSize.y == 0:
            graphics.screenSize = windowSize
        elif not settings.keepRatio:
            graphics.screenSize = vec2(
                settings.screenSize.x, 
                settings.screenSize.y * windowSize.y / windowSize.x
            )
        destroy(graphics.fb)
        graphics.fb = newRenderBuffer(graphics.screenSize)

proc `totalObjects`*(g: Graphics): int = g.totalObjects
proc `drawCalls`*(g: Graphics): int = g.drawCalls

proc clear*() =
    clear(graphics.context.shaders)
    clear(graphics.context.shadowCasters)
    clear(graphics.context.effects)
    add(graphics.context.shaders, graphics.shader)

proc renderToFrameBuffer(view, projection: Mat4, cubemap: Texture, drawables: var seq[Drawable]) =
    if not isNil(cubemap):
        render(
            graphics.skybox, 
            cubemap, 
            view, 
            projection, 
            graphics.context.environmentIntensity,
            graphics.context.environmentBlurrity,
        )

    # Resets render info
    graphics.totalObjects = 0
    graphics.totalBatches = 0
    graphics.drawCalls = 0

    var i = 0
    while i < len(drawables) and drawables[i].visible:
        let
            count = drawables[i].count 
            shader = if drawables[i].shader == nil: graphics.shader else: drawables[i].shader.instance
            albedo = if drawables[i].material != nil: drawables[i].material.albedoMap else: graphics.emptyTexture
            normal = if drawables[i].material != nil: drawables[i].material.normalMap else: graphics.emptyTexture
            metallic = if drawables[i].material != nil: drawables[i].material.metallicMap else: graphics.emptyTexture
            roughness = if drawables[i].material != nil: drawables[i].material.roughnessMap else: graphics.emptyTexture
            ao = if drawables[i].material != nil: drawables[i].material.aoMap else: graphics.emptyTexture
            emissive = if drawables[i].material != nil: drawables[i].material.emissiveMap else: graphics.emptyTexture
            mesh = drawables[i].mesh.instance

        use(shader)
        use(shader, graphics.skinTexture, "SKIN_MAP", 0)
        shader["ENVIRONMENT.SKIN_SAMPLER_WIDTH"] = graphics.skinTexture.width
        use(shader, albedo, "ALBEDO_MAP", 1)
        use(shader, normal, "NORMAL_MAP", 2)
        use(shader, metallic, "METALLIC_MAP", 3)
        use(shader, roughness, "ROUGHNESS_MAP", 4)
        use(shader, ao, "AO_MAP", 5)
        use(shader, emissive, "EMISSIVE_MAP", 6)

        # Renders count amount of instances
        render(
            mesh, 
            caddr(drawables[i].modelPack), 
            addr(drawables[i].materialPack[0]), 
            caddr(drawables[i].spritePack), 
            caddr(drawables[i].skinPack), 
            count
        )

        inc(graphics.totalObjects, count)
        inc(graphics.drawCalls)
        inc(i, count)
    
proc render*(view, projection: Mat4, cubemap: Texture, drawables: var seq[Drawable]) =
    # If there is shadow casters processes them
    if len(graphics.context.shadowCasters) > 0:
        process(graphics.shadow, graphics.context, drawables)

    # Binds to framebuffer
    use(graphics.fb, graphics.context.clearColor)

    # Renders objects to framebuffer
    renderToFrameBuffer(view, projection, cubemap, drawables)

    # Detachs from framebuffer
    detach(graphics.fb)

proc applyEffects(): Texture =
    if len(graphics.context.effects) > 0:
        if isNil(graphics.effectsFrameBuffer):
            graphics.effectsFrameBuffer = newFramebuffer()
            graphics.effectsTexture = newTexture2D(graphics.screenSize.iWidth, graphics.screenSize.iHeight, levels=1)
            allocate(graphics.effectsTexture)
        var 
            source = graphics.effectsTexture
            target = graphics.fb.color
        for shader in graphics.context.effects:
            swap(source, target)
            use(graphics.effectsFrameBuffer, target, GL_TEXTURE_2D.int, 0, graphics.screenSize.iWidth, graphics.screenSize.iHeight)
            use(shader)
            use(shader, source, "COLOR_CHANNEL", 0)
            use(shader, graphics.fb.depth, "DEPTH_CHANNEL", 1)
            draw(graphics.effectsFrameBuffer)
        result = target
    else:
        result = graphics.fb.color            


proc swap*() =
    let blitTexture = applyEffects()
    glBindRenderbuffer(GL_RENDERBUFFER, 0)
    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    glViewport(0, 0, graphics.windowSize.iWidth, graphics.windowSize.iHeight)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glDisable(GL_DEPTH_TEST)
    glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT)

    use(graphics.blitShader)
    use(graphics.blitShader, blitTexture, "COLOR_CHANNEL", 0)
    use(graphics.blitShader, graphics.fb.depth, "DEPTH_CHANNEL", 1)
    glDrawArrays(GL_TRIANGLES, 0, 3)
    glSwapWindow(graphics.window)
    glBindRenderbuffer(GL_RENDERBUFFER, 0)
    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    detach(blitTexture)

proc cleanupGraphics*() =
    destroy(graphics.skybox)
    graphics.skybox = nil
    destroy(graphics.fb)
    graphics.fb = nil
    destroy(graphics.shadow)
    graphics.shadow = nil
    destroy(graphics.emptyTexture)
    destroy(graphics.skinTexture)

    if graphics.glContext != nil:
        glDeleteContext(graphics.glContext)
        graphics.glContext = nil

    if graphics.window != nil:
        destroy(graphics.window)
        graphics.window = nil

proc `screenSize`*(g: Graphics): Vec2 = g.screenSize
#proc `context`*(g: Graphics): var GraphicContext = g.context
