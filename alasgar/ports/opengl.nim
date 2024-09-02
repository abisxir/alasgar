import strformat
import sdl2
import enums

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
    type
        OpenGLError = object of Defect
    proc printGlDebug(
        source, typ: GLenum,
        id: GLuint,
        severity: GLenum,
        length: GLsizei,
        message: ptr GLchar,
        userParam: pointer
        ) {.stdcall.} =
        let message = &"source=0x{source.uint32:0x} type=0x{typ.uint32:0x} id=0x{id.uint32:0x} severity=0x{severity.uint32:0x}: {$message}"
        #if severity == GL_DEBUG_SEVERITY_HIGH:
        #    raise newException(OpenGLError, message)
        #else:
        echo message

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

when defined(macosx):
    const
        OPENGL_PROFILE* = SDL_GL_CONTEXT_PROFILE_CORE
        OPENGL_MAJOR_VERSION* = 4
        OPENGL_MINOR_VERSION* = 1 
        OPENGL_SHADER_VERSION* = "410"
elif defined(windows):
    const
        OPENGL_PROFILE* = SDL_GL_CONTEXT_PROFILE_CORE
        OPENGL_MAJOR_VERSION* = 4
        OPENGL_MINOR_VERSION* = 6
        OPENGL_SHADER_VERSION* = "460"
elif defined(linux):
    const
        OPENGL_PROFILE* = SDL_GL_CONTEXT_PROFILE_ES
        OPENGL_MAJOR_VERSION* = 3
        OPENGL_MINOR_VERSION* = 0
        OPENGL_SHADER_VERSION* = "300 es"        
else:
    const
        OPENGL_PROFILE* = SDL_GL_CONTEXT_PROFILE_ES
        OPENGL_MAJOR_VERSION* = 3
        OPENGL_MINOR_VERSION* = 0
        OPENGL_SHADER_VERSION* = "300 es"

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

    # Loads opengl functions
    when declared(gladLoadGLES2):
        discard gladLoadGLES2(glGetProcAddress)
    else:
        discard gladLoadGL(glGetProcAddress)

    # Logs context info
    logContextInfo()

    # Sets debug callback
    when declared(glDebugMessageCallback):
        glDebugMessageCallback(printGlDebug, nil)
        glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS)
        glEnable(GL_DEBUG_OUTPUT)

    when declared(GL_TEXTURE_CUBE_MAP_SEAMLESS):
        glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS)

proc getOpenGLErrorString*(error: uint32): string = &"OpenGL error: {glEnumToString(error.uint32)}"

proc debugOpenGL*() =
    let 
        error = glGetError()
    if error.uint != GL_NO_ERROR:
        echo getOpenGLErrorString(error.uint32)
