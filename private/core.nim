## Core runtime and windowing API.
##
## This module exposes the engine entry point and the small set of shared
## runtime handles used by applications:
##
## - `window` starts the Sokol/OpenGL application loop.
## - `graphics` exposes framebuffer state such as `size`, `aspect`, and clear
##   `color`.
## - `runtime` exposes timing state such as `age`, `delta`, and `frames`.
## - `onWindowResize` registers callbacks for framebuffer resize events.

import std/strformat
import std/times

import sokol/app as sapp
import ports/opengl
import aljebra

export aljebra

when (defined(windows) or defined(macosx)) and not defined(gl):
  {.error: "The current renderer still uses raw OpenGL; compile with -d:gl when using Sokol on this platform.".}

type
  OnWindowResize = proc ()
  Window* = object
    ## Window configuration and current size.
    title: string
    size: UVec2
  Graphics* = object
    ## Graphics state shared with the active application.
    size: UVec2
    onWindowResizeCallbacks: seq[OnWindowResize]
    color*: Vec4 ## Clear color used at the start of each frame.
  Stats* = object
    drawCalls*: int
    vertices*: int
    indices*: int
    instances*: int
    batch*: int
  Runtime* = object
    ## Runtime timing counters updated once per frame.
    frames: int
    age, delta: float32
    time: float
    stats: Stats
  MouseInput* = object
    ## Mouse state accumulated from app events for the current frame.
    position*: Vec2
    delta*: Vec2
    scroll*: Vec2
    rightDown*: bool
  Engine* = object
    ## Internal engine state for the active application.
    app: sapp.Desc
    window: Window
    graphics: Graphics
    runtime: Runtime
    mouse: MouseInput
    stopped: bool
    load, draw, cleanup: proc()
    vsync: bool

var
  engine = Engine(vsync: true)

when defined(android):
  var
    androidDesc: sapp.Desc

let
  graphics*: ptr Graphics = addr engine.graphics ## Shared graphics state.
  runtime*: ptr Runtime = addr engine.runtime ## Shared runtime timing state.
  mouse*: ptr MouseInput = addr engine.mouse ## Shared mouse input state.

proc frameCallback() {.cdecl.} =
  engine.runtime.time = epochTime()
  engine.runtime.delta = sapp.frameDuration()
  engine.runtime.age += engine.runtime.delta
  engine.runtime.frames += 1
  engine.runtime.stats = Stats()

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

  engine.mouse.delta = vec2(0.0, 0.0)
  engine.mouse.scroll = vec2(0.0, 0.0)

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


proc eventCallback(event: ptr sapp.Event) {.cdecl.} =
  engine.mouse.position = vec2(event[].mouseX, event[].mouseY)

  case event[].`type`
  of eventTypeQuitRequested:
    engine.stopped = true
  of eventTypeKeyDown:
    if event[].keyCode in {keyCodeEscape, keyCodeQ}:
      engine.stopped = true
      sapp.quit()
  of eventTypeMouseDown:
    if event[].mouseButton == mouseButtonRight:
      engine.mouse.rightDown = true
  of eventTypeMouseUp:
    if event[].mouseButton == mouseButtonRight:
      engine.mouse.rightDown = false
  of eventTypeMouseMove:
    engine.mouse.delta = engine.mouse.delta + vec2(event[].mouseDx, event[].mouseDy)
  of eventTypeMouseScroll:
    engine.mouse.scroll = engine.mouse.scroll + vec2(event[].scrollX, event[].scrollY)
  of eventTypeResized:
    let
      width = event[].framebufferWidth
      height = event[].framebufferHeight
    engine.window.size = uvec2(width.uint32, height.uint32)
    engine.graphics.size = engine.window.size
    echo &"Window resized: ({width}, {height})"
    for cb in engine.graphics.onWindowResizeCallbacks:
      cb()
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

  engine.app = sapp.Desc(
    initCb: initCallback,
    frameCb: frameCallback,
    cleanupCb: cleanupCallback,
    eventCb: eventCallback,
    width: width.int32,
    height: height.int32,
    sampleCount: 1,
    swapInterval: (if engine.vsync: 1 else: 0),
    windowTitle: title.cstring,
    glMajorVersion: OPENGL_MAJOR_VERSION,
    glMinorVersion: OPENGL_MINOR_VERSION
  )

  when not defined(android):
    sapp.run(engine.app)

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

proc `fps`*(runtime: ptr Runtime): float32 =
  ## Return current frames per second.
  ##
  ## Example:
  ## ```nim
  ## echo runtime.fps
  ## ```
  1.0 / runtime.delta

proc `stats`*(runtime: ptr Runtime): Stats =
  ## Return the current frame's debug statistics.
  runtime.stats

proc recordDraw*(r: ptr Runtime, drawCalls, vertices, indices, instances: int) =
  ## Add one rendered submission to the current frame's debug statistics.
  r.stats.drawCalls += drawCalls
  r.stats.vertices += vertices
  r.stats.indices += indices
  r.stats.instances += instances
  if instances > 1:
    r.stats.batch += 1


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
  ## Register a callback for framebuffer resize events.
  ##
  ## Duplicate callbacks are ignored.
  ##
  ## Example:
  ## ```nim
  ## graphics.onWindowResize(proc (width, height: int32) =
  ##   echo "resized to ", width, "x", height
  ## )
  ## ```
  if slot notin g.onWindowResizeCallbacks:
    g.onWindowResizeCallbacks.add(slot)


proc alasgar_app_desc*(): sapp.Desc {.exportc: "alasgar_app_desc", cdecl.} =
  ## Return the application descriptor for the engine.
  ## This is specially useful when embedding the engine in an existing
  ## application. For example, to run the application from a C/C++
  ## program or an android app.
  engine.app
