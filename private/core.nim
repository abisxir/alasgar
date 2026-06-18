import std/strformat
import std/times

import sokol/app as sapp
import ports/opengl
import aljebra

when (defined(windows) or defined(macosx)) and not defined(gl):
  {.error: "The current renderer still uses raw OpenGL; compile with -d:gl when using Sokol on this platform.".}

type
  OnWindowResize = proc (width, height: int32)
  Window* = object
    title: string
    size: UVec2
  Graphics* = object
    size: UVec2
    onWindowResizeCallbacks: seq[OnWindowResize]
    color*: Vec4
  Runtime* = object
    frames: int
    age, delta, lastTicks: float32
  Engine* = object
    window: Window
    graphics: Graphics
    runtime: Runtime
    stopped: bool
    load, draw, cleanup: proc()
    vsync: bool

var
  engine = Engine(vsync: true)

let
  graphics*: ptr Graphics = addr engine.graphics
  runtime*: ptr Runtime = addr engine.runtime

proc frame() {.cdecl.} =
  let now = epochTime()
  engine.runtime.delta = now - engine.runtime.lastTicks
  engine.runtime.age += engine.runtime.delta
  engine.runtime.lastTicks = now
  engine.runtime.frames += 1

  #glBindRenderbuffer(GL_RENDERBUFFER, 0)
  #glBindFramebuffer(GL_FRAMEBUFFER, 0)
  glEnable(GL_DEPTH_TEST)
  let
    width = sapp.width()
    height = sapp.height()
  engine.window.size = uvec2(width.uint32, height.uint32)
  engine.graphics.size = engine.window.size
  glViewport(0, 0, width.GLsizei, height.GLsizei)
  #glEnable(GL_BLEND)
  #glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  #glDisable(GL_DEPTH_TEST)
  glClearColor(engine.graphics.color.x, engine.graphics.color.y, engine.graphics.color.z, engine.graphics.color.w)
  glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT)

  if engine.draw != nil:
    engine.draw()

proc cleanupCallback() {.cdecl.} =
  if engine.cleanup != nil:
    engine.cleanup()
    echo "* Resources cleaned up."
  echo "* Sokol window destroyed."

proc initCallback() {.cdecl.} =
  initOpenGL()
  echo "* Context initialized!"

  engine.window.size = uvec2(sapp.width().uint32, sapp.height().uint32)
  engine.graphics.size = engine.window.size
  engine.stopped = false

  if engine.load != nil:
    engine.load()

  engine.runtime.lastTicks = epochTime()

proc eventCallback(event: ptr sapp.Event) {.cdecl.} =
  case event[].`type`
  of eventTypeQuitRequested:
    engine.stopped = true
  of eventTypeKeyDown:
    if event[].keyCode in {keyCodeEscape, keyCodeQ}:
      engine.stopped = true
      sapp.quit()
  of eventTypeResized:
    let
      width = event[].framebufferWidth
      height = event[].framebufferHeight
    engine.window.size = uvec2(width.uint32, height.uint32)
    engine.graphics.size = engine.window.size
    echo &"Window resized: ({width}, {height})"
    for cb in engine.graphics.onWindowResizeCallbacks:
      cb(width, height)
  else:
    discard

proc window*(
  width, height: uint32,
  title: string,
  load, draw, cleanup: proc(),
) =
  ## Creates a window with the specified width, height, and title.
  ## It is the main entry point for the game loop.
  engine.window.title = title
  engine.window.size = uvec2(width, height)
  engine.graphics.size = engine.window.size
  engine.load = load
  engine.draw = draw
  engine.cleanup = cleanup

  sapp.run(sapp.Desc(
    initCb: initCallback,
    frameCb: frame,
    cleanupCb: cleanupCallback,
    eventCb: eventCallback,
    width: width.int32,
    height: height.int32,
    sampleCount: 1,
    swapInterval: (if engine.vsync: 1 else: 0),
    windowTitle: title.cstring,
    glMajorVersion: OPENGL_MAJOR_VERSION,
    glMinorVersion: OPENGL_MINOR_VERSION
  ))

proc `age`*(runtime: ptr Runtime): float32 =
  ## Return the age of the engine in seconds.
  ##
  ## Example:
  ## ```nim
  ## echo runtime.age
  ## ```
  runtime.age

proc `delta`*(runtime: ptr Runtime): float32 =
  ## Return the time elapsed since the last frame in seconds.
  ##
  ## Example:
  ## ```nim
  ## echo runtime.delta
  ## ```
  runtime.delta

proc `frames`*(runtime: ptr Runtime): int =
  ## Return the number of frames rendered since the start of the engine.
  ##
  ## Example:
  ## ```nim
  ## echo runtime.frames
  ## ```
  runtime.frames


proc `size`*(g: ptr Graphics): UVec2 =
  ## Return the render screen size.
  ##
  ## Example:
  ## ```nim
  ## let aspect = graphics.size.x.float32 / graphics.size.y.float32
  ## ```
  g.size


proc `aspect`*(g: ptr Graphics): float32 =
  ## Return the render screen aspect, 16/9 or etc.
  ##
  ## Example:
  ## ```nim
  ## let aspect = graphics.aspect
  ## ```
  g.size.x.float32 / g.size.y.float32


proc onWindowResize*(g: ptr Graphics, slot: OnWindowResize) =
  if slot notin g.onWindowResizeCallbacks:
    g.onWindowResizeCallbacks.add(slot)
