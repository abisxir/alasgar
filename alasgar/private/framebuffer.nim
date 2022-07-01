import ports/opengl

type
    FrameBuffer* = object
        id*: GLuint

proc newFramebuffer*(): FrameBuffer =
    glGenFramebuffers(1, addr(result.id))
    glBindFramebuffer(GL_FRAMEBUFFER, result.id)

proc destroy*(fb: FrameBuffer) =
    glDeleteFramebuffers(1, unsafeAddr(fb.id))

proc use*(fb: FrameBuffer) =
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id)