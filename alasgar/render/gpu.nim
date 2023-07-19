
import sdl2
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
            shader = if drawables[i].shader == nil: graphics.shader else: drawables[i].shader.instance
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

        if albedo != lastAlbedo:
            lastAlbedo = albedo
            use(lastShader, lastAlbedo, "ALBEDO_MAP", 1)

        if normal != lastNormal:
            lastNormal = normal
            use(lastShader, lastNormal, "NORMAL_MAP", 2)

        if metallic != lastMetallic:
            lastMetallic = metallic
            use(lastShader, lastMetallic, "METALLIC_MAP", 3)

        if roughness != lastRoughness:
            lastRoughness = roughness
            use(lastShader, lastRoughness, "ROUGHNESS_MAP", 4)

        if ao != lastAoMap:
            lastAoMap = ao
            use(lastShader, lastAoMap, "AO_MAP", 5)

        if emissive != lastEmissiveMap:
            lastEmissiveMap = emissive
            use(lastShader, lastEmissiveMap, "EMISSIVE_MAP", 6)

        # Limits instance count by max batch size
        var count = min(drawables[i].count, settings.maxBatchSize)

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
            use(shader, graphics.fb.normal, "NORMAL_CHANNEL", 1)
            use(shader, graphics.fb.depth, "DEPTH_CHANNEL", 2)
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
    use(graphics.blitShader, graphics.fb.normal, "NORMAL_CHANNEL", 1)
    use(graphics.blitShader, graphics.fb.depth, "DEPTH_CHANNEL", 2)
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

    if graphics.glContext != nil:
        glDeleteContext(graphics.glContext)
        graphics.glContext = nil

    if graphics.window != nil:
        destroy(graphics.window)
        graphics.window = nil


proc `screenSize`*(g: Graphics): Vec2 = g.screenSize
#proc `context`*(g: Graphics): var GraphicContext = g.context
