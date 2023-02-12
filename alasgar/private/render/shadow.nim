import ../ports/opengl
import ../utils
import ../shader
import ../core
import context
import fb


const forwardDepthV = staticRead("shaders/forward-depth.vs")
const forwardDepthF = staticRead("shaders/forward-depth.fs")


type
    DepthBuffer* = ref object
        fbo: GLuint
        texture: GLuint
        cube: GLuint
        size: Vec2
    Shadow* = ref object
        shader: Shader
        fbo: Framebuffer
        buffers: seq[DepthBuffer]

proc newDepthBuffer*(size: Vec2): DepthBuffer =
    new(result)

    # Sets size and clear color
    result.size = size

    glGenTextures(1, addr(result.texture))
    glBindTexture(GL_TEXTURE_2D, result.texture)
    glTexImage2D(
        GL_TEXTURE_2D, 
        0, 
        GL_DEPTH_COMPONENT32F.GLint, 
        size.iWidth, 
        size.iHeight, 
        0, 
        GL_DEPTH_COMPONENT, 
        cGL_FLOAT, 
        nil
    )
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE.GLint) 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE.GLint)

    # Creates frame buffer object
    glGenFramebuffers(1, addr(result.fbo))
    glBindFramebuffer(GL_FRAMEBUFFER, result.fbo)
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, result.texture, 0)

    if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
        quit("ERROR::FRAMEBUFFER:: Framebuffer is not complete!")

    glBindFramebuffer(GL_FRAMEBUFFER, 0)


proc newCubeDepthBuffer*(size: int): DepthBuffer =
    new(result)

    # Sets size and clear color
    result.size = vec2(size.float32, size.float32)

    glGenTextures(1, addr(result.texture))
    glBindTexture(GL_TEXTURE_2D, result.texture)
    glTexImage2D(
        GL_TEXTURE_2D, 
        0, 
        GL_DEPTH_COMPONENT32F.GLint, 
        size.GLsizei, 
        size.GLsizei, 
        0, 
        GL_DEPTH_COMPONENT, 
        cGL_FLOAT, 
        nil
    )
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE.GLint) 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE.GLint)

    glGenTextures(1, addr(result.cube))
    glBindTexture(GL_TEXTURE_CUBE_MAP, result.texture)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR.GLint)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR.GLint)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE.GLint) 
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE.GLint)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE.GLint)
    for i in 0..5:
        glTexImage2D(
            (GL_TEXTURE_CUBE_MAP_POSITIVE_X.int + i).GLenum, 
            0.GLint, 
            GL_R32F.GLint, 
            size.GLsizei, 
            size.GLsizei, 
            0.GLint, 
            GL_RED, 
            cGL_FLOAT, 
            nil
        )

    # Creates frame buffer object
    glGenFramebuffers(1, addr(result.fbo))
    glBindFramebuffer(GL_FRAMEBUFFER, result.fbo)
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, result.texture, 0)

    if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
        quit("ERROR::FRAMEBUFFER:: Framebuffer is not complete!")

    glBindFramebuffer(GL_FRAMEBUFFER, 0)

proc use*(f: DepthBuffer) =
    glViewport(0, 0, f.size.iWidth, f.size.iHeight)
    glBindFramebuffer(GL_FRAMEBUFFER, f.fbo)
    glEnable(GL_CULL_FACE)
    glCullFace(GL_FRONT)
    glEnable(GL_DEPTH_TEST)
    glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT)

proc attach*(f: DepthBuffer, shader: Shader) =
    shader["u_depth_map"] = 0
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, f.texture)

proc destroy*(fb: DepthBuffer) =
    if fb.fbo != 0:
        glDeleteFramebuffers(1, addr(fb.fbo))
        fb.fbo = 0
    if fb.texture != 0:
        glDeleteTextures(1, addr(fb.texture))
        fb.texture = 0

proc newShadow*(): Shadow =
    new(result)
    result.shader = newShader(forwardDepthV, forwardDepthF, [])
    result.fbo = newFramebuffer()

proc provideDepthBuffer(shadow: Shadow, size: Vec2): DepthBuffer =
    for i, buffer in pairs(shadow.buffers):
        if buffer.size == size:
            del(shadow.buffers, i)
            return buffer
    return newDepthBuffer(size)

proc process*(shadow: Shadow, 
              context: var GraphicContext,
              drawables: var seq[Drawable]) = 
    var buffers = newSeq[DepthBuffer]()
    for j, caster in mpairs(context.shadowCasters):
        let buffer = provideDepthBuffer(shadow, caster.size)
        add(buffers, buffer)
        use(buffer)
        use(shadow.shader)
        shadow.shader["u_shadow_mvp"] = caster.projection * caster.view * identity()

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

        for shader in context.shaders:
            use(shader)
            shader[&"u_depth_map_{j}"] = GL_TEXTURE0.int + 7 + j
            glActiveTexture((GL_TEXTURE0.int + 7 + j).GLenum)
            glBindTexture(GL_TEXTURE_2D, buffer.texture)

    # Brings used buffers back to shadow instance
    shadow.buffers = buffers

proc destroy*(shadow: Shadow) =
    if shadow != nil:
        if shadow.shader != nil:
            shadow.shader = nil
            destroy(shadow.shader)
            for buffer in shadow.buffers:
                destroy(buffer)
