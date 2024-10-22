import stb_image/write as stbi

import ../ports/opengl
import ../utils
import ../texture

type
    FrameBuffer* = ref object
        fbo*: GLuint
        #rbo: GLuint
        color*: Texture 
        depth*: Texture
    
    EffectFrameBuffer* = ref object
        fbo: GLuint

proc checkFramebuffer() =
    let fbStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER)
    if fbStatus != GL_FRAMEBUFFER_COMPLETE:
        raise newAlasgarError(&"ERROR::FRAMEBUFFER:: Framebuffer is incomplete, status: 0x{fbStatus.int:0x}")


proc newRenderBuffer*(size: Vec2): FrameBuffer =
    new(result)

    # Creates frame buffer object
    glGenFramebuffers(1, addr(result.fbo))
    glBindFramebuffer(GL_FRAMEBUFFER, result.fbo)

    # Creates texture
    result.color = newTexture2D(
        width=size.iWidth, 
        height=size.iHeight, 
        minFilter=GL_NEAREST,
        magFilter=GL_NEAREST,
        wrapT=GL_CLAMP_TO_EDGE,
        wrapS=GL_CLAMP_TO_EDGE,
    )
    allocate(result.color)
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, result.color.id, 0)

    result.depth = newTexture2D(
        width=size.iWidth, 
        height=size.iHeight, 
        internalFormat=GL_DEPTH_COMPONENT32F,
        format=GL_DEPTH_COMPONENT,
        minFilter=GL_NEAREST,
        magFilter=GL_NEAREST,
        wrapT=GL_CLAMP_TO_EDGE,
        wrapS=GL_CLAMP_TO_EDGE,
        dataType=cGL_FLOAT,
    )
    allocate(result.depth, GL_DEPTH_COMPONENT, cGL_FLOAT)
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, result.depth.id, 0)

    #var buffers = [GL_COLOR_ATTACHMENT0]
    #glDrawBuffers(1, buffers[0].addr)
    
    checkFramebuffer()
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0)

proc newFramebuffer*(): FrameBuffer =
    new(result)
   
    # Creates frame buffer object
    glGenFramebuffers(1, addr(result.fbo))
    glBindFramebuffer(GL_FRAMEBUFFER, result.fbo)
    glBindFramebuffer(GL_FRAMEBUFFER, 0)


proc use*(f: FrameBuffer, background: Color) =
    glBindFramebuffer(GL_FRAMEBUFFER, f.fbo)
    #glBindRenderbuffer(GL_RENDERBUFFER, f.rbo)
    glViewport(0, 0, f.color.width, f.color.height)

    glDisable(GL_CULL_FACE)
    glEnable(GL_DEPTH_TEST)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glDepthFunc(GL_LESS)

    glClearColor(background.r, background.g, background.b, 1)
    glClear(GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

proc use*(fb: FrameBuffer, texture: Texture, target, level, width, height: int) =
    glBindFramebuffer(GL_FRAMEBUFFER, fb.fbo)
    attach(texture)
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, target.GLenum, texture.id, level.GLint)
    checkFramebuffer()
    glViewport(0, 0, width.GLsizei, height.GLsizei)
    glClear(GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

proc use*(fb: FrameBuffer, texture: Texture, attachment: GLenum) =
    glBindFramebuffer(GL_FRAMEBUFFER, fb.fbo)
    glFramebufferTexture2D(GL_FRAMEBUFFER, attachment, texture.target, texture.id, 0.GLint)
    checkFramebuffer()
    glViewport(0, 0, texture.width.GLsizei, texture.height.GLsizei)
    glClear(GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)


proc use*(fb: FrameBuffer, texture: Texture, attachment: GLenum, level, layer: int) =
    glBindFramebuffer(GL_FRAMEBUFFER, fb.fbo)
    glBindTexture(texture.target, texture.id)
    glFramebufferTextureLayer(GL_FRAMEBUFFER, attachment, texture.id, level.GLint, layer.GLint)
    checkFramebuffer()
    glViewport(0, 0, texture.width.GLsizei, texture.height.GLsizei)
    glClear(GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)


proc draw*(fb: FrameBuffer) = glDrawArrays(GL_TRIANGLES, 0, 3)
proc detach*(fb: FrameBuffer) = glBindFramebuffer(GL_FRAMEBUFFER, 0)

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
        if fb.color != nil:
            destroy(fb.color)
            fb.color = nil
        if fb.depth != nil:
            destroy(fb.depth)
            fb.depth = nil
        #if fb.rbo != 0:
        #    glDeleteRenderbuffers(1, addr(fb.rbo))
        #    fb.rbo = 0
        if fb.fbo != 0:
            glDeleteFramebuffers(1, addr(fb.fbo))
            fb.fbo = 0
