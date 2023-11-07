import ../ports/opengl
import ../utils
import ../shaders/base
import ../shaders/compile
import ../shaders/depth
import ../core
import context
import fb


type
    Shadow* = ref object
        shader: Shader
        fb: Framebuffer
        textureArray: Texture

proc newShadow*(): Shadow =
    new(result)
    result.shader = newSpatialShader(depthVertex, depthFragment)
    result.fb = newFramebuffer()

proc provideTextures(shadow: Shadow, context: GraphicsContext) =
    var 
        lightCount = 0
        pointLightCount = 0
    for c in context.shadowCasters:
        if not c.point:
            inc(lightCount)
        else:
            inc(pointLightCount)
    if lightCount > 0:
        if shadow.textureArray != nil and shadow.textureArray.layers < lightCount:
            destroy(shadow.textureArray)
            shadow.textureArray = nil
        if isNil(shadow.textureArray):
            shadow.textureArray = newTexture(
                GL_TEXTURE_2D_ARRAY,
                settings.depthMapSize, 
                settings.depthMapSize, 
                minFilter=GL_LINEAR,
                magFilter=GL_LINEAR, 
                internalFormat=GL_DEPTH_COMPONENT32F,
                layers=lightCount
            )            
            glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_REF_TO_TEXTURE.GLint)
            glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_COMPARE_FUNC, GL_LEQUAL.GLint)
            allocate(shadow.textureArray, format=GL_DEPTH_COMPONENT, dataType=cGL_FLOAT)
            

proc renderDepthMap(drawables: var seq[Drawable]) =
    var i = 0
    while i < len(drawables) and drawables[i].visible:
        # Selects mesh
        var mesh = drawables[i].mesh.instance

        # Limits instance count by max batch size
        var count = min(drawables[i].count, settings.maxBatchSize)

        for ix in 0..<count:
            if drawables[i + ix].material != nil and drawables[i + ix].material.castShadow:
                # Renders count amount of instances
                render(
                    mesh, 
                    caddr(drawables[i + ix].modelPack), 
                    addr(drawables[i + ix].materialPack[0]), 
                    caddr(drawables[i + ix].spritePack), 
                    caddr(drawables[i + ix].skinPack), 
                    1
                )
        # Moves to next chunk
        inc(i, count)    

proc process*(shadow: Shadow, 
              context: var GraphicsContext,
              drawables: var seq[Drawable]) = 
    glEnable(GL_DEPTH_TEST)
    provideTextures(shadow, context)
    for j, caster in mpairs(context.shadowCasters):
        use(
            shadow.fb, 
            shadow.textureArray, 
            GL_DEPTH_ATTACHMENT,
            0,
            j
        )
        glEnable(GL_CULL_FACE)
        glCullFace(GL_FRONT)
        use(shadow.shader)
        shadow.shader["SHADOW_MVP"] = caster.projection * caster.view
        renderDepthMap(drawables)
        detach(shadow.fb)

    for shader in context.shaders:
        use(shader)
        use(shader, shadow.textureArray, "DEPTH_MAPS", 8)

proc destroy*(shadow: Shadow) =
    if shadow != nil:
        if shadow.shader != nil:
            destroy(shadow.shader)
            shadow.shader = nil
        if shadow.fb != nil:
            destroy(shadow.fb)
            shadow.fb = nil
        if shadow.textureArray != nil:
            destroy(shadow.textureArray)
            shadow.textureArray = nil
