import stb_image/write as stbi

import ../ports/opengl
import ../utils
import ../shader
import context

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
    glBufferData(GL_ARRAY_BUFFER, (sizeof(quadVertices)).GLsizeiptr, addr(quadVertices[0]), GL_STATIC_DRAW);
    glEnableVertexAttribArray(0)
    glVertexAttribPointer(0, 2, cGL_FLOAT, false, (4 * sizeof(float32)).GLsizei, cast[pointer](0))
    glEnableVertexAttribArray(1)
    glVertexAttribPointer(1, 2, cGL_FLOAT, false, (4 * sizeof(float32)).GLsizei, cast[pointer](2 * sizeof(float32)))
    glBindVertexArray(0)
    glBindBuffer(GL_ARRAY_BUFFER, 0)    


proc use*(f: FrameBuffer, clearColor: Color) =
    glBindFramebuffer(GL_FRAMEBUFFER, f.fbo)
    glViewport(0, 0, f.size.iWidth, f.size.iHeight)

    glDisable(GL_CULL_FACE)
    glEnable(GL_DEPTH_TEST)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glDepthFunc(GL_LESS)

    glClearColor(clearColor.r, clearColor.g, clearColor.b, 1)
    glClear(GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

proc blit*(f: FrameBuffer, context: GraphicContext) =
    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    glDisable(GL_DEPTH_TEST)
    glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT)
    
    use(f.shader)

    f.shader["iResolution"] = vec3(f.size.x, f.size.y, 1.0);
    f.shader["u_fxaa"] = if context.fxaaEnabled: 1 else: 0
    f.shader["u_fxaa_span_max"] = context.fxaaSpanMax
    f.shader["u_fxaa_reduce_mul"] = context.fxaaReduceMul
    f.shader["u_fxaa_reduce_min"] = context.fxaaReduceMin
    
    glBindVertexArray(f.quadVAO)
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, f.texture)
    glDrawArrays(GL_TRIANGLES, 0, 6)

proc saveImage*() =
    let 
        width = 1024.GLsizei
        height = 1024.GLsizei
        nrChannels = 3.GLsizei
    var stride = nrChannels * width
    if stride mod 4 != 0: 
        stride += (4 - stride mod 4)
    var 
        bufferSize = stride * height
        buffer = newSeq[byte](bufferSize)

    glPixelStorei(GL_PACK_ALIGNMENT, 4)
    glReadBuffer(GL_FRONT)
    glReadPixels(0, 0, width, height, GL_RGB, GL_UNSIGNED_BYTE, addr buffer[0])
    stbi.writePNG("/tmp/depth.png", width.int, height.int, nrChannels.int, buffer, stride.int)
