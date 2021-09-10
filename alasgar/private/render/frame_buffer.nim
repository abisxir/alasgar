import ../ports/opengl
import ../utils
import ../texture
import ../shader
import shaders/deferred_shading_frag
import shaders/deferred_shading_vert


const forwardPostV = staticRead("shaders/forward-post.vs")
const forwardPostF = staticRead("shaders/forward-post.fs")


type
    FrameBufferObj = object
        deferred: bool
        fbo: GLuint
        rbo: GLuint
        quadVAO: GLuint
        quadVBO: GLuint
        size: Vec2
        shader: Shader

        positionBuffer*: GLuint
        normalBuffer*: GLuint
        albedoBuffer*: GLuint
        shadowBuffer*: GLuint

    FrameBuffer* = ref FrameBufferObj

proc `=destroy`*(fb: var FrameBufferObj) =
    # Clear g buffers
    if fb.albedoBuffer != 0:
        glDeleteTextures(1, addr(fb.albedoBuffer))
        fb.albedoBuffer = 0
    if fb.positionBuffer != 0:
        glDeleteTextures(1, addr(fb.positionBuffer))
        fb.positionBuffer = 0
    if fb.normalBuffer != 0:
        glDeleteTextures(1, addr(fb.normalBuffer))
        fb.normalBuffer = 0

    if fb.quadVBO != 0:
        glDeleteBuffers(1, addr(fb.quadVBO))
        fb.quadVBO = 0
    if fb.quadVAO != 0:
        glDeleteVertexArrays(1, addr(fb.quadVAO))
        fb.quadVAO = 0
    if fb.rbo != 0:
        glDeleteRenderbuffers(1, addr(fb.rbo))
        fb.rbo = 0
    if fb.fbo != 0:
        glDeleteFramebuffers(1, addr(fb.fbo))
        fb.fbo = 0

proc createPassBuffer(size: Vec2, index: int, internalFormat: GLenum, format: GLenum, dataType: GLenum): GLuint =
    glGenTextures(1, addr(result))
    glBindTexture(GL_TEXTURE_2D, result)
    glTexImage2D(GL_TEXTURE_2D, 0, internalFormat.GLint, size.x.GLsizei, size.y.GLsizei, 0.GLint, format, dataType, nil)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)
    glFramebufferTexture2D(GL_FRAMEBUFFER, (GL_COLOR_ATTACHMENT0.int + index).GLenum, GL_TEXTURE_2D, result, 0)

proc newFrameBuffer*(size: Vec2, deferred: bool=false, multiSample: int=4): FrameBuffer =
    new(result)

    # Sets size and clear color
    result.size = size
    result.deferred = deferred

    # Attaches shaders
    if deferred:
        result.shader = newShader(deferred_shading_vert.source, deferred_shading_frag.source, [])
    else:
        result.shader = newShader(forwardPostV, forwardPostF, [])

    # Creates frame buffer object
    glGenFramebuffers(1, addr(result.fbo))
    glBindFramebuffer(GL_FRAMEBUFFER, result.fbo)

    # If it is deferred, then it creates G buffer
    if deferred:
        # Creates pass buffers
        result.albedoBuffer = createPassBuffer(size, 2, GL_RGBA, GL_RGBA, GL_UNSIGNED_BYTE)
        result.positionBuffer = createPassBuffer(size, 0, GL_RGB16F, GL_RGB, cGL_FLOAT)
        result.normalBuffer = createPassBuffer(size, 1, GL_RGBA16F, GL_RGBA, cGL_FLOAT)
        var attachments = [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1, GL_COLOR_ATTACHMENT2, GL_COLOR_ATTACHMENT3]
        glDrawBuffers(3, addr(attachments[0]))
    else:
        # Creates pass buffers
        result.albedoBuffer = createPassBuffer(size, 2, GL_RGBA, GL_RGBA, GL_UNSIGNED_BYTE)
        glGenTextures(1, addr(result.albedoBuffer))
        glBindTexture(GL_TEXTURE_2D, result.albedoBuffer)
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, size.x.GLsizei, size.y.GLsizei, 0.GLint, GL_RGBA, GL_UNSIGNED_BYTE, nil)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)
        #glRenderbufferStorageMultisample(GL_RENDERBUFFER, multiSample, GL_DEPTH_COMPONENT16, textureSize, textureSize)
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, result.albedoBuffer, 0)

    glGenRenderbuffers(1, addr(result.rbo))
    glBindRenderbuffer(GL_RENDERBUFFER, result.rbo)
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, size.iWidth, size.iHeight)
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, result.rbo)

    if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
        quit("ERROR::FRAMEBUFFER:: Framebuffer is not complete!")
    glBindFramebuffer(GL_FRAMEBUFFER, 0)

    var quadVertices= [
        -1'f32,  1'f32,  0'f32, 1'f32,
        -1'f32, -1'f32,  0'f32, 0'f32,
         1'f32, -1'f32,  1'f32, 0'f32,

        -1'f32,  1'f32,  0'f32, 1'f32,
         1'f32, -1'f32,  1'f32, 0'f32,
         1'f32,  1'f32,  1'f32, 1'f32
    ]

    glGenVertexArrays(1, addr(result.quadVAO))
    glGenBuffers(1, addr(result.quadVBO))
    glBindVertexArray(result.quadVAO);
    glBindBuffer(GL_ARRAY_BUFFER, result.quadVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(quadVertices), addr(quadVertices[0]), GL_STATIC_DRAW);
    glEnableVertexAttribArray(0)
    glVertexAttribPointer(0, 2, cGL_FLOAT, false, (4 * sizeof(float32)).GLsizei, cast[pointer](0))
    glEnableVertexAttribArray(1)
    glVertexAttribPointer(1, 2, cGL_FLOAT, false, (4 * sizeof(float32)).GLsizei, cast[pointer](2 * sizeof(float32)))
    glBindVertexArray(0)
    glBindBuffer(GL_ARRAY_BUFFER, 0)    

proc use*(f: FrameBuffer, clearColor: Color) =
    glBindFramebuffer(GL_FRAMEBUFFER, f.fbo)
    glViewport(0, 0, f.size.iWidth, f.size.iHeight)

    glEnable(GL_DEPTH_TEST)
    glDisable(GL_CULL_FACE)
    #glEnable(GL_CULL_FACE)
    #glCullFace(GL_BACK)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    glClearColor(clearColor.r, clearColor.g, clearColor.b, 1)
    glClear(GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
    #glStencilMask(0xFF) # Android requires setting stencil mask to clear
    #glClear(GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
    #glStencilMask(0x00)


proc blit*(f: FrameBuffer) =
    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    glDisable(GL_DEPTH_TEST)

    #glClear(bitand(GL_COLOR_BUFFER_BIT, GL_DEPTH_BITS))

    use(f.shader)
    glBindVertexArray(f.quadVAO)

    if f.deferred:
        glActiveTexture(GL_TEXTURE0)
        glBindTexture(GL_TEXTURE_2D, f.positionBuffer)
        glActiveTexture(GL_TEXTURE1)
        glBindTexture(GL_TEXTURE_2D, f.normalBuffer)
        glActiveTexture(GL_TEXTURE2)
        glBindTexture(GL_TEXTURE_2D, f.albedoBuffer)
    else:
        glActiveTexture(GL_TEXTURE0)
        glBindTexture(GL_TEXTURE_2D, f.albedoBuffer)

    #use(texture, 0)
    glDrawArrays(GL_TRIANGLES, 0, 6)


proc blit*(f: FrameBuffer, texture: GLuint) =
    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    glDisable(GL_DEPTH_TEST)

    use(f.shader)
    glBindVertexArray(f.quadVAO)

    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, texture)

    #use(texture, 0)
    glDrawArrays(GL_TRIANGLES, 0, 6)

