import stb_image/write as stbi

import ../ports/opengl
import ../utils
import ../texture

type
    FrameBuffer* = ref object
        fbo*: GLuint
        rbo: GLuint
        color*: Texture 
        normal*: Texture
        depth*: Texture
    
    EffectFrameBuffer* = ref object
        fbo: GLuint

proc newRenderBuffer*(size: Vec2): FrameBuffer =
    new(result)

    # Creates texture
    result.color = newTexture2D(
        width=size.iWidth, 
        height=size.iHeight, 
        #minFilter=GL_LINEAR,
        #magFilter=GL_LINEAR,
        #wrapT=GL_CLAMP_TO_EDGE,
        #wrapS=GL_CLAMP_TO_EDGE,
    )
    allocate(result.color)

    result.normal = newTexture2D(
        width=size.iWidth, 
        height=size.iHeight, 
        internalFormat=GL_RGB16F,
        format=GL_RGB,
        minFilter=GL_LINEAR,
        magFilter=GL_LINEAR,
        wrapT=GL_CLAMP_TO_EDGE,
        wrapS=GL_CLAMP_TO_EDGE,
        dataType=cGL_FLOAT,
    )
    allocate(result.normal)

    result.depth = newTexture2D(
        width=size.iWidth, 
        height=size.iHeight, 
        internalFormat=GL_DEPTH_COMPONENT16,
        format=GL_DEPTH_COMPONENT,
        minFilter=GL_NEAREST,
        magFilter=GL_NEAREST,
        wrapT=GL_CLAMP_TO_EDGE,
        wrapS=GL_CLAMP_TO_EDGE,
        dataType=cGL_FLOAT,
    )
    allocate(result.depth)

    # Creates frame buffer object
    glGenFramebuffers(1, addr(result.fbo))
    glBindFramebuffer(GL_FRAMEBUFFER, result.fbo)

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, result.depth.id, 0)
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, result.color.id, 0)
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, result.normal.id, 0)

    var buffers = [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1]
    glDrawBuffers(2, buffers[0].addr)

    # Creates render buffer object
    #glGenRenderbuffers(1, addr(result.rbo))
    #glBindRenderbuffer(GL_RENDERBUFFER, result.rbo)
    #glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, result.color.width, result.color.height)
    #glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, result.rbo)
    #glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, result.color.width, result.color.height)
    #glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, result.rbo)

    if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
        quit("ERROR::FRAMEBUFFER:: Framebuffer is not complete!")
        
    #glBindRenderbuffer(GL_RENDERBUFFER, 0)
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

proc use*(fb: FrameBuffer, texture: Texture, unit, level, width, height: int) =
    glBindFramebuffer(GL_FRAMEBUFFER, fb.fbo)
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, unit.GLenum, texture.id, level.GLint)
    attach(texture)
    glViewport(0, 0, width.GLsizei, height.GLsizei)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

proc use*(fb: FrameBuffer, texture: Texture, attachment: GLenum, unit: int) =
    glViewport(0, 0, texture.width.GLsizei, texture.height.GLsizei)
    glBindFramebuffer(GL_FRAMEBUFFER, fb.fbo)
    glFramebufferTexture2D(GL_FRAMEBUFFER, attachment, unit.GLenum, texture.id, 0.GLint)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

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
        if fb.normal != nil:
            destroy(fb.normal)
            fb.normal = nil
        if fb.depth != nil:
            destroy(fb.depth)
            fb.depth = nil
        if fb.rbo != 0:
            glDeleteRenderbuffers(1, addr(fb.rbo))
            fb.rbo = 0
        if fb.fbo != 0:
            glDeleteFramebuffers(1, addr(fb.fbo))
            fb.fbo = 0