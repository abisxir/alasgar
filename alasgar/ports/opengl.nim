import strformat

import sdl2

import glad

export glad

proc printGlDebug(
    source, typ: GLenum,
    id: GLuint,
    severity: GLenum,
    length: GLsizei,
    message: ptr GLchar,
    userParam: pointer
    ) {.stdcall.} =
    echo &"source={source.uint32:0x} type={typ.uint32:0x} id={id} severity={severity.uint32:0x}: {$message}"


proc logContextInfo() =
    echo "Device and render info:"
    var 
        linked: SDL_Version
        version = cast[cstring](glGetString(GL_VERSION))
        vendor = cast[cstring](glGetString(GL_VENDOR))
        renderer = cast[cstring](glGetString(GL_RENDERER))
        maxVaryingVectors: GLint
    
    getVersion(linked)
    glGetIntegerv(GL_MAX_VARYING_VECTORS, addr maxVaryingVectors)

    echo &"  SDL linked version  : {linked.major}.{linked.minor}.{linked.patch}"
    echo &"  Version: {version}"
    echo &"  Vendor: {vendor}"
    echo &"  Renderer: {renderer}"
    echo &"  Max varying vectors: {maxVaryingVectors}"


proc createOpenGLContext*(window: WindowPtr): GlContextPtr =
    # Initialize opengl context
    when defined(macosx):
        discard glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE)
        discard glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4)
        discard glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1)
        discard glSetAttribute(SDL_GL_RED_SIZE, 8)
        discard glSetAttribute(SDL_GL_GREEN_SIZE, 8)
        discard glSetAttribute(SDL_GL_BLUE_SIZE, 8)
        discard glSetAttribute(SDL_GL_ALPHA_SIZE, 8)
        discard glSetAttribute(SDL_GL_STENCIL_SIZE, 8)
    else:
        discard glSetAttribute(SDL_GL_SHARE_WITH_CURRENT_CONTEXT, 1)
        discard glSetAttribute(SDL_GL_DOUBLEBUFFER, 1)
        discard glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES)
        discard glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3)
        discard glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0)
    

    # Creates opengl context
    result = glCreateContext(window)

    # Checks that opengl context has created
    if result == nil:
        quit "Could not create context!"

    # Activates opengl context
    discard glMakeCurrent(window, result)

    # Loads opengl es
    discard gladLoadGLES2(glGetProcAddress)

    # Logs context info
    logContextInfo()

    # Sets debug callback
    when defined(glDebugMessageCallback):
        glDebugMessageCallback(printGlDebug, nil)
        glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS)
        glEnable(GL_DEBUG_OUTPUT)
