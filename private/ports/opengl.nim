import strformat
import enums

when defined(windows):
  import gl460
  export gl460
  const
    OPENGL_MAJOR_VERSION* = 4
    OPENGL_MINOR_VERSION* = 6
    OPENGL_SHADER_VERSION* = "460"
elif defined(macosx):
  import gl410
  export gl410
  const
    OPENGL_MAJOR_VERSION* = 4
    OPENGL_MINOR_VERSION* = 1
    OPENGL_SHADER_VERSION* = "410"
else:
  import gles300
  export gles300
  const
    OPENGL_MAJOR_VERSION* = 3
    OPENGL_MINOR_VERSION* = 0
    OPENGL_SHADER_VERSION* = "300 es"

when declared(glDebugMessageCallback):
  proc printGlDebug(
        source, typ: GLenum,
        id: GLuint,
        severity: GLenum,
        length: GLsizei,
        message: ptr GLchar,
        userParam: pointer
        ) {.stdcall.} =
    let
      converted = cast[cstring](message)
      formatted = &"source=0x{source.uint32:0x} type=0x{typ.uint32:0x} id=0x{id.uint32:0x} severity=0x{severity.uint32:0x}: {$message}"
    #if severity == GL_DEBUG_SEVERITY_HIGH:
    #    raise newException(OpenGLError, message)
    #else:
    echo formatted

when defined(windows):
  proc wglGetProcAddress(name: cstring): pointer {.stdcall, importc, dynlib: "opengl32".}
  proc loadOpenGLProc(name: cstring): pointer {.cdecl.} = wglGetProcAddress(name)
elif defined(macosx):
  import std/dynlib
  var openGLHandle: LibHandle
  proc loadOpenGLProc(name: cstring): pointer {.cdecl.} =
    if openGLHandle == nil:
      openGLHandle = loadLib("/System/Library/Frameworks/OpenGL.framework/OpenGL")
    if openGLHandle != nil:
      result = symAddr(openGLHandle, $name)
elif defined(emscripten):
  proc emscripten_webgl_get_proc_address(name: cstring): pointer {.cdecl, importc.}
  proc loadOpenGLProc(name: cstring): pointer {.cdecl.} =
    emscripten_webgl_get_proc_address(name)
elif defined(android):
  proc eglGetProcAddress(name: cstring): pointer {.cdecl, importc.}
  proc loadOpenGLProc(name: cstring): pointer {.cdecl.} = eglGetProcAddress(name)
elif defined(linux):
  proc glXGetProcAddressARB(name: ptr GLubyte): pointer {.cdecl, importc, dynlib: "libGL.so.1".}
  proc loadOpenGLProc(name: cstring): pointer {.cdecl.} =
    glXGetProcAddressARB(cast[ptr GLubyte](name))
else:
  proc eglGetProcAddress(name: cstring): pointer {.cdecl, importc, dynlib: "EGL".}
  proc loadOpenGLProc(name: cstring): pointer {.cdecl.} = eglGetProcAddress(name)

proc logContextInfo() =
  echo "Device and render info:"
  var
    version = cast[cstring](glGetString(GL_VERSION))
    vendor = cast[cstring](glGetString(GL_VENDOR))
    renderer = cast[cstring](glGetString(GL_RENDERER))
    maxVaryingVectors: GLint

  glGetIntegerv(GL_MAX_VARYING_VECTORS, addr maxVaryingVectors)

  echo &"  Version: {version}"
  echo &"  Vendor: {vendor}"
  echo &"  Renderer: {renderer}"
  echo &"  Max varying vectors: {maxVaryingVectors}"

proc initOpenGL*() =
  when declared(gladLoadGLES2):
    if not gladLoadGLES2(loadOpenGLProc):
      quit "Could not load OpenGL ES functions."
  else:
    if not gladLoadGL(loadOpenGLProc):
      quit "Could not load OpenGL functions."

  logContextInfo()

  when declared(glDebugMessageCallback):
    glDebugMessageCallback(printGlDebug, nil)
    glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS)
    glEnable(GL_DEBUG_OUTPUT)

proc getOpenGLErrorString*(error: uint32): string = &"OpenGL error: {glEnumToString(error.uint32)}"

proc debugOpenGL*() =
  let
    error = glGetError()
  if error.uint != GL_NO_ERROR:
    echo getOpenGLErrorString(error.uint32)
