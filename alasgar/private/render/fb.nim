import stb_image/write as stbi

import ../ports/opengl
import ../utils
import ../texture

type
    FrameBuffer* = ref object
        fbo: GLuint
        rbo: GLuint
        texture*: Texture 
    
    EffectFrameBuffer* = ref object
        fbo: GLuint

proc newRenderBuffer*(size: Vec2): FrameBuffer =
    new(result)

    # Creates texture
    result.texture = newTexture2D(size.iWidth, size.iHeight)
    allocate(result.texture)

    # Creates frame buffer object
    glGenFramebuffers(1, addr(result.fbo))
    glBindFramebuffer(GL_FRAMEBUFFER, result.fbo)
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, result.texture.id, 0)

    # Creates render buffer object
    glGenRenderbuffers(1, addr(result.rbo))
    glBindRenderbuffer(GL_RENDERBUFFER, result.rbo)
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, result.texture.width, result.texture.height)
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, result.rbo)

    if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
        quit("ERROR::FRAMEBUFFER:: Framebuffer is not complete!")
        
    glBindRenderbuffer(GL_RENDERBUFFER, 0)
    glBindFramebuffer(GL_FRAMEBUFFER, 0)

proc newFrameBuffer*(): FrameBuffer =
    new(result)
   
    # Creates frame buffer object
    glGenFramebuffers(1, addr(result.fbo))
    glBindFramebuffer(GL_FRAMEBUFFER, result.fbo)
    glBindFramebuffer(GL_FRAMEBUFFER, 0)


proc use*(f: FrameBuffer, background: Color) =
    glBindFramebuffer(GL_FRAMEBUFFER, f.fbo)
    glBindRenderbuffer(GL_RENDERBUFFER, f.rbo)
    glViewport(0, 0, f.texture.width, f.texture.height)

    glDisable(GL_CULL_FACE)
    glEnable(GL_DEPTH_TEST)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glDepthFunc(GL_LESS)

    glClearColor(background.r, background.g, background.b, 1)
    glClear(GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

proc use*(fb: FrameBuffer, texture: Texture, unit, level, width, height: int) =
    glBindFramebuffer(GL_FRAMEBUFFER, fb.fbo)
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, unit.GLenum, texture.id, level.GLint)
    attach(texture)
    glViewport(0, 0, width.GLsizei, height.GLsizei)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

proc draw*(fb: FrameBuffer) = glDrawArrays(GL_TRIANGLES, 0, 3)

proc saveImage*(path: string) =
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
    stbi.writePNG(path, width.int, height.int, nrChannels.int, buffer, stride.int)

proc destroy*(fb: FrameBuffer) =
    if fb != nil:
        # Clear g buffers
        if fb.texture != nil:
            destroy(fb.texture)
            fb.texture = nil
        if fb.rbo != 0:
            glDeleteRenderbuffers(1, addr(fb.rbo))
            fb.rbo = 0
        if fb.fbo != 0:
            glDeleteFramebuffers(1, addr(fb.fbo))
            fb.fbo = 0
