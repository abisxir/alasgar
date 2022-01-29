import ../ports/opengl
import ../utils
import ../shader


const forwardPostV = staticRead("shaders/forward-post.vs")
const forwardPostF = staticRead("shaders/forward-post.fs")

type
    FrameBuffer* = ref object
        fbo: GLuint
        rbo: GLuint
        quadVAO: GLuint
        quadVBO: GLuint
        size: Vec2
        shader: Shader
        texture: GLuint


proc newCanvasShader*(source: string): Shader =
    var 
        vsource = forwardPostV
        fsource = forwardPostF
            
    if isEmptyOrWhitespace(source):
        fsource = fsource
            .replace("$MAIN_FUNCTION$", "")
            .replace("$MAIN_FUNCTION_CALL$", "")
    else:
        fsource = fsource
            .replace("$MAIN_FUNCTION$", source)
            .replace("$MAIN_FUNCTION_CALL$", """
    iColor = out_fragment_color;
    mainImage(out_fragment_color, v_uv);
""")
    result = newShader(vsource, fsource, [])


proc destroy*(fb: FrameBuffer) =
    # Clear g buffers
    if fb.texture != 0:
        glDeleteTextures(1, addr(fb.texture))
        fb.texture = 0

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

proc newFrameBuffer*(size: Vec2, deferred: bool=false, multiSample: int=4): FrameBuffer =
    new(result)

    # Sets size and clear color
    result.size = size

    # Attaches shaders
    result.shader = newCanvasShader("")

    # Creates frame buffer object
    glGenFramebuffers(1, addr(result.fbo))
    glBindFramebuffer(GL_FRAMEBUFFER, result.fbo)

    # Creates pass buffers
    glGenTextures(1, addr(result.texture))
    glBindTexture(GL_TEXTURE_2D, result.texture)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, size.x.GLsizei, size.y.GLsizei, 0.GLint, GL_RGBA, GL_UNSIGNED_BYTE, nil)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, result.texture, 0)

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
    #glClear(GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
    glStencilMask(0xFF) # Android requires setting stencil mask to clear
    glClear(GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
    glStencilMask(0x00)


proc blit*(f: FrameBuffer) =
    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    glDisable(GL_DEPTH_TEST)
    glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT)
    use(f.shader)
    glBindVertexArray(f.quadVAO)
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, f.texture)
    glDrawArrays(GL_TRIANGLES, 0, 6)
