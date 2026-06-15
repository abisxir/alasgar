import std/strformat
import std/times

import ports/sdl2
import ports/opengl
import aljebra


when defined(emscripten):
  proc emscripten_set_main_loop(f: proc() {.cdecl.}, a: cint, b: cint) {.importc.}
  proc emscripten_cancel_main_loop() {.importc.}

type
  Window* = object
    title: string
    size: UVec2
    reference: WindowPtr
  Graphics* = object
    size: UVec2
    ctx: GlContextPtr
    color*: Vec4
  Runtime* = object
    frames: int
    age, delta, lastTicks: float32
    event: Event
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

proc update(): bool =
  while pollEvent(engine.runtime.event):
    if engine.runtime.event.kind == QuitEvent:
      engine.stopped = true
    elif engine.runtime.event.kind == KeyDown and (engine.runtime.event.evKeyboard.keysym.scancode == SDL_SCANCODE_ESCAPE or engine.runtime.event.evKeyboard.keysym.scancode == SDL_SCANCODE_Q):
      engine.stopped = true
    elif engine.runtime.event.kind == WindowEvent:
      var windowEvent = cast[WindowEventPtr](addr(engine.runtime.event))
      if windowEvent.event == WindowEvent_Resized:
        let width = windowEvent.data1
        let height = windowEvent.data2
        #resizeGraphics(vec2(width.float32, height.float32))
        echo &"Window resized: ({width}, {height})"
    # Maps SDL event to alasgar event object
    #parseEvent(addr runtime.evt, graphics.windowSize, addr input)
  result = not engine.stopped

proc frame() =
  let now = epochTime()
  engine.runtime.delta = now - engine.runtime.lastTicks
  engine.runtime.age += engine.runtime.delta
  engine.runtime.lastTicks = now
  engine.runtime.frames += 1

  #glBindRenderbuffer(GL_RENDERBUFFER, 0)
  #glBindFramebuffer(GL_FRAMEBUFFER, 0)
  glEnable(GL_DEPTH_TEST)
  glViewport(0, 0, engine.window.size.x.GLsizei, engine.window.size.y.GLsizei)
  #glEnable(GL_BLEND)
  #glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  #glDisable(GL_DEPTH_TEST)
  glClearColor(engine.graphics.color.x, engine.graphics.color.y, engine.graphics.color.z, engine.graphics.color.w)
  glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT)

  engine.draw()

  glSwapWindow(engine.window.reference)

proc cleanup() =
  if engine.cleanup != nil:
    engine.cleanup()
    echo "* Resources cleaned up."
  if engine.graphics.ctx != nil:
    glDeleteContext(engine.graphics.ctx)
    engine.graphics.ctx = nil
    echo "* Graphics context destroyed."
  if engine.window.reference != nil:
    destroy(engine.window.reference)
    engine.window.reference = nil
    echo "* Window destroyed."

when defined(emscripten):
  proc runEmscriptenGameLoop() {.cdecl.} =
    if update():
      frame()
    else:
      cleanup()
else:
  proc runGameLoop() =
    while update():
      frame()
    cleanup()

proc window*(
  width, height: uint32,
  title: string,
  load, draw, cleanup: proc(),
) =
  ## Creates a window with the specified width, height, and title.
  ## It is the main entry point for the game loop.
  when defined(emscripten):
    emscripten_set_main_loop(handleFrameWhenEmscripten, 0, 0)

  discard sdl2.init(INIT_EVERYTHING)
  echo "* SDL initialized."

  engine.window.title = title
  engine.window.size = uvec2(width, height)

  let flags = SDL_WINDOW_OPENGL or SDL_WINDOW_SHOWN
  when defined(ios) or defined(android):
    flags = SDL_WINDOW_OPENGL or SDL_WINDOW_FULLSCREEN
  elif defined(emscripten):
    flags = SDL_WINDOW_OPENGL

  # Initialize SDL windows
  engine.window.reference = createWindow(
    title.cstring,
    SDL_WINDOWPOS_UNDEFINED,
    SDL_WINDOWPOS_UNDEFINED,
    width.cint,
    height.cint,
    flags
  )

  echo "* SDL window created!"
  let size = engine.window.reference.getSize()
  echo &"* Actual window size: ({size.x}, {size.y})"
  engine.window.size = uvec2(size.x.uint32, size.y.uint32)

  engine.graphics.ctx = createOpenGLContext(engine.window.reference)
  engine.graphics.size = uvec2(size.x.uint32, size.y.uint32)
  echo "* Context initialized!"
  engine.stopped = false

  engine.load = load
  engine.draw = draw
  engine.cleanup = cleanup

  if engine.load != nil:
    engine.load()

  engine.runtime.lastTicks = epochTime()

  when defined(emscripten):
    emscripten_set_main_loop(runEmscriptenGameLoop, 0, 0)
  else:
    if engine.vsync:
      discard glSetSwapInterval(1.cint)
    else:
      discard glSetSwapInterval(0.cint)
    runGameLoop()


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
