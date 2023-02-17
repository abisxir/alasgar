import ../ports/opengl
import ../utils
import ../shader
import ../core
import context
import fb


const forwardDepthV = staticRead("shaders/forward-depth.vs")
const forwardDepthF = staticRead("shaders/forward-depth.fs")


type
    Shadow* = ref object
        shader: Shader
        fb: Framebuffer

proc newShadow*(): Shadow =
    new(result)
    result.shader = newShader(forwardDepthV, forwardDepthF, [])
    result.fb = newFramebuffer()

proc renderDepthMap(drawables: var seq[Drawable]) =
    var i = 0
    while i < len(drawables) and drawables[i].visible:
        # Selects mesh
        var mesh = drawables[i].mesh.instance

        # Limits instance count by max batch size
        var count = min(drawables[i].count, settings.maxBatchSize)

        for ix in 0..count - 1:
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
              context: var GraphicContext,
              drawables: var seq[Drawable]) = 
    for j, caster in mpairs(context.shadowCasters):
        use(shadow.fb, caster.shadowMap, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D.int)
        glEnable(GL_CULL_FACE)
        glCullFace(GL_FRONT)
        glEnable(GL_DEPTH_TEST)
        use(shadow.shader)
        shadow.shader["u_shadow_mvp"] = caster.projection * caster.view * identity()

        renderDepthMap(drawables)

        for shader in context.shaders:
            use(shader)
            shader[&"u_depth_map_{j}"] = GL_TEXTURE0.int + 7 + j
            glActiveTexture((GL_TEXTURE0.int + 7 + j).GLenum)
            glBindTexture(GL_TEXTURE_2D, caster.shadowMap.id)
        
        detach(shadow.fb)

proc destroy*(shadow: Shadow) =
    if shadow != nil:
        if shadow.shader != nil:
            destroy(shadow.shader)
            shadow.shader = nil
        if shadow.fb != nil:
            destroy(shadow.fb)
            shadow.fb = nil
