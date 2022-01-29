import ../ports/opengl
import ../utils
import ../shader


const forwardDepthV = staticRead("shaders/forward-depth.vs")
const forwardDepthF = staticRead("shaders/forward-depth.fs")


type
    DepthBuffer* = ref object
        fbo: GLuint
        texture*: GLuint
        size: Vec2
        shader*: Shader

proc destroy*(fb: DepthBuffer) =
    if fb.fbo != 0:
        glDeleteFramebuffers(1, addr(fb.fbo))
        fb.fbo = 0
    if fb.texture != 0:
        glDeleteTextures(1, addr(fb.texture))
        fb.texture = 0


proc newDepthBuffer*(size: Vec2): DepthBuffer =
    new(result)

    # Sets size and clear color
    result.size = size
    result.shader = newShader(forwardDepthV, forwardDepthF, [])

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


proc use*(f: DepthBuffer) =
    glViewport(0, 0, f.size.iWidth, f.size.iHeight)
    glBindFramebuffer(GL_FRAMEBUFFER, f.fbo)
    glEnable(GL_CULL_FACE)
    glCullFace(GL_FRONT)
    glEnable(GL_DEPTH_TEST)
    glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT)
    use(f.shader)

proc attach*(f: DepthBuffer, shader: Shader) =
    shader["u_depth_map"] = 0
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, f.texture)

