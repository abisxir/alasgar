## Core runtime, windowing, and application lifecycle API.
##
## Applications normally configure the shared `graphics` and `runtime` handles,
## define their lifecycle callbacks, and pass those callbacks to `window`:
##
## ```nim
## proc load() =
##   graphics.color = vec4(0.08, 0.09, 0.12, 1.0)
##
## proc draw() =
##   discard
##
## proc cleanup() =
##   discard
##
## runtime.exitOnEscape = true
## window(960, 540, "My application", load, draw, cleanup)
## ```
##
## `graphics` provides framebuffer state and graphics lifecycle hooks. `runtime`
## provides frame timing, input hooks, and rendering statistics. The pointers
## remain valid for the lifetime of the process and are managed by the engine;
## callers must not free them.

import std/strformat
import std/times

import sokol/app as sapp
import ports/opengl
import aljebra

export aljebra, sapp.Event

when (defined(windows) or defined(macosx)) and not defined(gl):
  {.error: "The current renderer still uses raw OpenGL; compile with -d:gl when using Sokol on this platform.".}

type
  Callback = proc ()
  InputCallback = proc (e: ptr sapp.Event)
  Window* = object
    ## Opaque window configuration and state owned by the engine.
    title*: string
    size*: UVec2
  Graphics* = object
    ## Graphics state owned by the engine and accessed through `graphics`.
    size: UVec2
    onWindowResizeCallbacks: seq[Callback]
    onLoadCallbacks: seq[Callback]
    onCleanupCallbacks: seq[Callback]
    color*: Vec4
      ## RGBA clear color applied to the color buffer before each `draw` call.
  Stats* = object
    ## Rendering counters for the current frame.
    ##
    ## The engine resets these values at the beginning of every frame. Rendering
    ## code updates them through `recordDraw`.
    drawCalls*: int ## Number of recorded rendering submissions.
    vertices*: int ## Total number of submitted vertices.
    indices*: int ## Total number of submitted indices.
    instances*: int ## Total number of submitted instances.
    batch*: int ## Number of recorded submissions containing multiple instances.
  Settings* = object
    ## Contains application settings, like starting fullscreen etc.
    fullscreen*: bool
      ## Requests a fullscreen window when supported by the platform.
    exitOnEscape*: bool
      ## Whether pressing Escape or Q requests application shutdown, when platform supports
    msaa*: int
      ## Multisample anti-aliasing sample count, for example 4 for 4× MSAA.
  Runtime* = object
    ## Runtime state owned by the engine and accessed through `runtime`.
    frames: int
    age, delta: float32
    time: float
    stats: Stats
    onInputCallbacks: seq[InputCallback]
  Engine* = object
    ## Opaque state for the active engine instance.
    ##
    ## Applications use `graphics`, `runtime`, and `window` instead of creating
    ## this type directly.
    app: sapp.Desc
    window: Window
    graphics: Graphics
    runtime: Runtime
    settings: Settings
    stopped: bool
    load, draw, cleanup: proc()
    vsync: bool

var
  engine = Engine(vsync: true, settings: Settings(fullscreen: false, exitOnEscape: false, msaa: 1))

when defined(android):
  var
    androidDesc: sapp.Desc

let
  graphics*: ptr Graphics = addr engine.graphics
    ## Process-wide graphics state managed by the engine.
  runtime*: ptr Runtime = addr engine.runtime
    ## Process-wide runtime state managed by the engine.
  settings*: ptr Settings = addr engine.settings

proc frameCallback() {.cdecl.} =
  engine.runtime.time = epochTime()
  engine.runtime.delta = sapp.frameDuration()
  engine.runtime.age += engine.runtime.delta
  engine.runtime.frames += 1
  engine.runtime.stats = Stats()

  glEnable(GL_DEPTH_TEST)
  let
    width = sapp.width()
    height = sapp.height()
  engine.window.size = uvec2(width.uint32, height.uint32)
  engine.graphics.size = engine.window.size
  glViewport(0, 0, width.GLsizei, height.GLsizei)
  glClearColor(engine.graphics.color.x, engine.graphics.color.y, engine.graphics.color.z, engine.graphics.color.w)
  glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT)

  if engine.draw != nil:
    engine.draw()

proc cleanupCallback() {.cdecl.} =
  for cb in graphics.onCleanupCallbacks:
    cb()
  if engine.cleanup != nil:
    engine.cleanup()
    echo "* Resources cleaned up."
  echo "* Window destroyed."

proc initCallback() {.cdecl.} =
  initOpenGL()
  echo "* Context initialized!"

  engine.window.size = uvec2(sapp.width().uint32, sapp.height().uint32)
  engine.graphics.size = engine.window.size
  engine.stopped = false

  if engine.load != nil:
    engine.load()
    for cb in engine.graphics.onLoadCallbacks:
      cb()


proc eventCallback(event: ptr sapp.Event) {.cdecl.} =
  for cb in runtime.onInputCallbacks:
    cb(event)
  case event[].`type`
  of eventTypeQuitRequested:
    engine.stopped = true
  of eventTypeKeyDown:
    when not defined(emscripten):
      engine.stopped = settings.exitOnEscape and event[].keyCode in {keyCodeEscape, keyCodeQ}
    if engine.stopped:
      sapp.quit()
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
  ## Configure the application and start its windowing loop.
  ##
  ## `width` and `height` specify the initial framebuffer dimensions in pixels.
  ## `title` is used as the native window title.
  ##
  ## Once the graphics context is ready, `load` runs once. `draw` then runs once
  ## per frame after the color and depth buffers have been cleared. During
  ## shutdown, callbacks registered with `onCleanup` run before `cleanup`.
  ##
  ## On non-Android targets this procedure enters Sokol's application loop and
  ## does not return until that loop exits. On Android it only prepares the
  ## descriptor returned by `alasgar_app_desc`; the host application owns the
  ## loop.
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
    fullscreen: engine.settings.fullscreen,
    sampleCount: engine.settings.msaa.int32,
    swapInterval: (if engine.vsync: 1 else: 0),
    windowTitle: title.cstring,
    glMajorVersion: OPENGL_MAJOR_VERSION,
    glMinorVersion: OPENGL_MINOR_VERSION
  )

  when not defined(android):
    sapp.run(engine.app)

proc `window`*(runtime: ptr Runtime): Window =
  ## Return window properties
  ##
  ## Example:
  ## ```nim
  ## echo runtime.window.size
  ## ```
  discard runtime
  engine.window

proc `age`*(runtime: ptr Runtime): float32 =
  ## Return elapsed engine time in seconds.
  ##
  ## The value starts at zero and accumulates `delta` once per rendered frame.
  ##
  ## Example:
  ## ```nim
  ## echo runtime.age
  ## ```
  runtime.age

proc `delta`*(runtime: ptr Runtime): float32 =
  ## Return the duration of the latest frame in seconds.
  ##
  ## Example:
  ## ```nim
  ## echo runtime.delta
  ## ```
  runtime.delta

proc `frames`*(runtime: ptr Runtime): int =
  ## Return the number of frames started since engine initialization.
  ##
  ## Example:
  ## ```nim
  ## echo runtime.frames
  ## ```
  runtime.frames

proc `fps`*(runtime: ptr Runtime): float32 =
  ## Return the instantaneous frame rate derived from `delta`.
  ##
  ## This is `1.0 / runtime.delta`; it is not a smoothed average and is only
  ## meaningful after frame timing has been initialized.
  ##
  ## Example:
  ## ```nim
  ## echo runtime.fps
  ## ```
  1.0 / runtime.delta

proc `stats`*(runtime: ptr Runtime): Stats =
  ## Return a snapshot of the current frame's rendering counters.
  ##
  ## Counters are reset at the beginning of every frame and populated by calls
  ## to `recordDraw`.
  runtime.stats

proc recordDraw*(r: ptr Runtime, drawCalls, vertices, indices, instances: int) =
  ## Add rendering work to the current frame's statistics.
  ##
  ## Each argument is added to its corresponding counter. A call whose
  ## `instances` value is greater than one also increments `Stats.batch` once.
  ## This procedure records bookkeeping only; it does not issue a GPU command.
  r.stats.drawCalls += drawCalls
  r.stats.vertices += vertices
  r.stats.indices += indices
  r.stats.instances += instances
  if instances > 1:
    r.stats.batch += 1


proc `size`*(g: ptr Graphics): UVec2 =
  ## Return the current framebuffer width and height in pixels.
  ##
  ## Example:
  ## ```nim
  ## let aspect = graphics.size.x.float32 / graphics.size.y.float32
  ## ```
  g.size


proc `aspect`*(g: ptr Graphics): float32 =
  ## Return the current framebuffer aspect ratio as width divided by height.
  ##
  ## Example:
  ## ```nim
  ## let aspect = graphics.aspect
  ## ```
  g.size.x.float32 / g.size.y.float32


proc onWindowResize*(g: ptr Graphics, slot: Callback) =
  ## Register `slot` to run after the framebuffer size changes.
  ##
  ## The engine updates `graphics.size` before invoking the callback. Registering
  ## the same callback more than once has no effect.
  ##
  ## Example:
  ## ```nim
  ## graphics.onWindowResize(proc () =
  ##   echo "resized to ", graphics.size.x, "x", graphics.size.y
  ## )
  ## ```
  if slot notin g.onWindowResizeCallbacks:
    g.onWindowResizeCallbacks.add(slot)


proc onInput*(r: ptr Runtime, slot: InputCallback) =
  ## Register `slot` to receive Sokol application events.
  ##
  ## Input callbacks run before the engine's built-in quit, keyboard, and resize
  ## handling. The event pointer is borrowed and is only valid for the duration
  ## of the callback. Registering the same callback more than once has no effect.
  ##
  ## Example:
  ## ```nim
  ## runtime.onInput(proc (event: ptr sapp.Event) =
  ##   echo (event.mouseX, event.mouseY)
  ## )
  ## ```
  if slot notin r.onInputCallbacks:
    r.onInputCallbacks.add(slot)


proc onLoad*(g: ptr Graphics, slot: Callback) =
  ## Register `slot` to run once after the application's `load` callback.
  ##
  ## The graphics context is initialized before either callback runs.
  ## Registering the same callback more than once has no effect.
  ##
  ## Example:
  ## ```nim
  ## graphics.onLoad(proc () =
  ##   echo "Graphics loaded!"
  ## )
  ## ```
  if slot notin g.onLoadCallbacks:
    g.onLoadCallbacks.add(slot)

proc onCleanup*(g: ptr Graphics, slot: Callback) =
  ## Register `slot` to run during application shutdown.
  ##
  ## Registered slots run before the `cleanup` callback passed to `window`.
  ## Registering the same callback more than once has no effect.
  ##
  ## Example:
  ## ```nim
  ## graphics.onCleanup(proc () =
  ##   echo "Cleanup things!"
  ## )
  ## ```
  if slot notin g.onCleanupCallbacks:
    g.onCleanupCallbacks.add(slot)


proc alasgar_app_desc*(): sapp.Desc {.exportc: "alasgar_app_desc", cdecl.} =
  ## Return the Sokol application descriptor configured by `window`.
  ##
  ## This C-callable entry point is intended for hosts that own the application
  ## loop, such as an Android or embedded C/C++ application. Call `window` first
  ## to populate the descriptor. The exported C symbol is `alasgar_app_desc`.
  engine.app
