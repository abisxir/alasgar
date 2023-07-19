import strformat

import sdl2

when defined(windows):
    import gl460
    export gl460
elif defined(macosx):
    import gl410
    export gl410
else:
    import gles300
    export gles300

when declared(glDebugMessageCallback):
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

const
    OPENGL_PROFILE* = when defined(macosx) or defined(windows): SDL_GL_CONTEXT_PROFILE_CORE else: SDL_GL_CONTEXT_PROFILE_ES
    OPENGL_MAJOR_VERSION* = when defined(macosx) or defined(windows): 4 else: 3
    OPENGL_MINOR_VERSION* = when defined(macosx): 1 elif defined(windows): 6 else: 0
    OPENGL_SHADER_VERSION* = when defined(macosx): "410" elif defined(windows): "460" else: "300 es"

proc createOpenGLContext*(window: WindowPtr): GlContextPtr =
    # Initialize opengl context
    discard glSetAttribute(SDL_GL_SHARE_WITH_CURRENT_CONTEXT, 1)
    discard glSetAttribute(SDL_GL_DOUBLEBUFFER, 1)
    discard glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, OPENGL_PROFILE)
    discard glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, OPENGL_MAJOR_VERSION.cint)
    discard glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, OPENGL_MINOR_VERSION.cint)
    
    # Creates opengl context
    result = glCreateContext(window)

    # Checks that opengl context has created
    if result == nil:
        quit "Could not create context!"

    # Activates opengl context
    discard glMakeCurrent(window, result)

    # Loads opengl es
    when defined(windows) or defined(macosx):
        discard gladLoadGL(glGetProcAddress)
    else:
        discard gladLoadGLES2(glGetProcAddress)

    # Logs context info
    logContextInfo()

    # Sets debug callback
    when declared(glDebugMessageCallback):
        glDebugMessageCallback(printGlDebug, nil)
        glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS)
        glEnable(GL_DEBUG_OUTPUT)

    when declared(GL_TEXTURE_CUBE_MAP_SEAMLESS):
        glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS)
