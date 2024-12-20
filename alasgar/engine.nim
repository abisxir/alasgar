import strformat
import tables
import times
import os

when defined(emscripten):
    proc emscripten_set_main_loop(f: proc() {.cdecl.}, a: cint, b: cint) {.importc.}
    proc emscripten_cancel_main_loop() {.importc.}
    
import ports/sdl2

import logger
import render/gpu
import core
import input
import utils
import system
import systems/render
import systems/prepare
import systems/traverse
import components/script
import components/camera
import components/light
import components/interactive
import components/skin
import components/animation
import components/catmull
import components/sound
import components/timer
import resources/resource
import shaders/base
import physics/ray

when defined(emscripten):
    proc handleFrameWhenEmscripten() {.cdecl.}

type
    Engine* = object
        title: string
        primary*: Scene
        systems: seq[System]
        inputSystems: seq[System]
        ratio: float32
        newPrimary: Scene
        oldPrimary: Scene
    Runtime* = object
        evt: Event
        engine: Engine
        runGame: bool
        age: float32
        frames: int
        delta: float32
        lastTicks:float
        eventProcessTime: float
        systemBenchmark: Table[string, float]

var runtime*: Runtime

proc `activeCamera`*(e: Engine): CameraComponent =
    if e.primary != nil:
        e.primary.activeCamera
    else:
        nil

proc addSystem*(system: System, before: System = nil,
        after: System = nil) =
    if before != nil and contains(runtime.engine.systems, before):
        var i = find(runtime.engine.systems, before)
        if i + 1 >= len runtime.engine.systems:
            add(runtime.engine.systems, system)
        else:
            insert(runtime.engine.systems, system, i)
    elif after != nil and contains(runtime.engine.systems, after):
        var i = find(runtime.engine.systems, after) + 1
        if i + 1 >= len runtime.engine.systems:
            add(runtime.engine.systems, system)
        else:
            insert(runtime.engine.systems, system, i)
    else:
        add(runtime.engine.systems, system)


proc initEngine*(windowWidth: int,
                 windowHeight: int,
                 title: string = "Alasgar",
                 fullscreen: bool = false,
                 resizable: bool = false) =
    when defined(emscripten):
        emscripten_set_main_loop(handleFrameWhenEmscripten, 0, 0)
    
    discard sdl2.init(INIT_EVERYTHING)
    echo "* SDL initialized."

    runtime.engine.title = title

    var flags = SDL_WINDOW_OPENGL or SDL_WINDOW_SHOWN

    if fullscreen: 
        flags = flags or SDL_WINDOW_FULLSCREEN_DESKTOP 
    elif resizable:
        flags = flags or SDL_WINDOW_RESIZABLE
            
    when defined(ios) or defined(android):
        flags = SDL_WINDOW_OPENGL or SDL_WINDOW_FULLSCREEN
    elif defined(emscripten):
        flags = SDL_WINDOW_OPENGL

    # Initialize SDL windows
    let window = createWindow(
        runtime.engine.title.cstring,
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        windowWidth.cint,
        windowHeight.cint,
        flags
    )

    echo "* SDL window created!"

    # If the window is fullscreen, specially in mobile devices, window size is going to be perhaps different
    let actualSize = window.getSize()
    runtime.engine.ratio = actualSize.x.float32 / actualSize.y.float32

    let sw = if settings.screenSize.iWidth > 0: settings.screenSize.iWidth else: actualSize.x
    let sh = if settings.screenSize.iHeight > 0: settings.screenSize.iHeight else: actualSize.y

    # Creates graphic object
    initGraphics(
        window,
        screenSize=vec2(sw.float32, sh.float32),
        windowSize=vec2(
            actualSize.x.float32,
            actualSize.y.float32
        ),
        vsync=false,
    )

    setBufferSizeOf(sizeof(Drawable))

    # Create systems
    addSystem(newTimerSystem())
    addSystem(newScriptSystem())
    addSystem(newCatmullSystem())
    addSystem(newAnimationSystem())
    addSystem(newTraverseSystem())
    addSystem(newJointSystem())
    addSystem(newSkinSystem())
    addSystem(newPrepareSystem())
    addSystem(newCameraSystem())
    addSystem(newSoundSystem())
    addSystem(newLightSystem())
    addSystem(newRenderSystem())

    add(runtime.engine.inputSystems, newInputSystem())
    add(runtime.engine.inputSystems, newInteractiveSystem())

    for e in runtime.engine.systems:
        init(e)

    runtime.age = 0.0
    runtime.frames = 0
    runtime.lastTicks = epochTime()
    runtime.eventProcessTime = 0.0
    runtime.systemBenchmark = initTable[string, float]()
    for sys in runtime.engine.systems:
        runtime.systemBenchmark[sys.name] = 0.float


proc pushSystem*(system: System, before: System = nil,
        after: System = nil) =
    insert(runtime.engine.systems, system, 0)


proc destroy*() =
    #if not isNil(runtime.engine.primary):
    #    destroy(runtime.engine.primary)
    #    runtime.engine.primary = nil
    #

    # Cleans systems up
    for e in runtime.engine.systems:
        cleanup(e)

    # Finally, quits SDL
    sdl2.quit()

proc handleFrame() =
    # Calculates delta time between current frame and the last drawn frame
    var 
        now = epochTime()
        delta = now - runtime.lastTicks
        age = 0'f32
        sleepTime = 0'f32
        frameLimit = if settings.maxFPS > 0: 1'f32 / settings.maxFPS.float32 else: 0'f32
        scene = runtime.engine.primary

    if not isNil(scene):
        # Cleans up the scene, removes dangling entities
        cleanup(scene)

    when not defined(emscripten):
        if delta > 0 and delta < frameLimit:
            sleepTime = frameLimit - delta 
            while sleepTime > 0 and delta < frameLimit:
                sleep(0)
                now = epochTime()
                delta = now - runtime.lastTicks
    
    # Updates last tick with the current time
    runtime.lastTicks = now
    # Keeps age of running system
    age += delta
    runtime.age += delta
    runtime.frames += 1
    runtime.delta = delta

    # Updates fps each seconds
    if age >= 1.0:
        age = 0.0
        if settings.verbose:
            echo &"Counted frames: {runtime.frames}"
            echo &"FPS: {1.0 / delta}"
            echo &"  Drawable objects: {len(scene.drawables)}"
            echo &"  Visible objects: {graphics.totalObjects}"
            echo &"  Draw calls: {graphics.drawCalls}"

            var totalSystemTime = 0.float
            for key, value in mpairs(runtime.systemBenchmark):
                echo &"    + {key:<24}: {value}"
                totalSystemTime += value
                value = 0.float
            echo &"    + Events                  : {runtime.eventProcessTime}"
            echo &"    + Sleep                   : {sleepTime}"
            echo &"    = {delta}"

        runtime.frames = 0

    # Marks start of processing events
    let eventStart = epochTime()

    # Pulls SDL event and passes to the nodes that need event processing
    while pollEvent(runtime.evt):
        var input: Input
        # Set mouse position, even if there is not event.
        updateMousePosition(addr input)
        if runtime.evt.kind == QuitEvent:
            runtime.runGame = false
        elif settings.exitOnEsc and runtime.evt.kind == KeyDown and (runtime.evt.evKeyboard.keysym.scancode == SDL_SCANCODE_ESCAPE or runtime.evt.evKeyboard.keysym.scancode == SDL_SCANCODE_Q):
            runtime.runGame = false
        elif runtime.evt.kind == WindowEvent:
            var windowEvent = cast[WindowEventPtr](addr(runtime.evt))
            if windowEvent.event == WindowEvent_Resized:
                let width = windowEvent.data1
                let height = windowEvent.data2
                resizeGraphics(vec2(width.float32, height.float32))
                logi &"Window resized: ({width}, {height})"
        # Maps SDL event to alasgar event object
        parseEvent(addr runtime.evt, graphics.windowSize, addr input)
        if not isNil(scene):
            for system in runtime.engine.inputSystems:
                process(system, runtime.engine.primary, input, runtime.delta, runtime.frames, runtime.age)
    
    # Calculates event processing elapsed time 
    runtime.eventProcessTime = epochTime() - eventStart

    if isNil(runtime.engine.newPrimary):
        if isNil(scene):
            echo "No scene to render!"
        elif isNil(scene.activeCamera):
            echo "No active camera!"
        else:
            # Clear scene
            clear()
            for system in runtime.engine.systems:
                var 
                    start = epochTime()
                    input: Input
                process(system, runtime.engine.primary, input, delta, runtime.frames, runtime.age)
                runtime.systemBenchmark[system.name] = epochTime() - start
    else:
        destroy(runtime.engine.primary)
        runtime.engine.primary = runtime.engine.newPrimary
        runtime.engine.newPrimary = nil
    
when defined(emscripten):
    proc handleFrameWhenEmscripten() {.cdecl.} = 
        if runtime.runGame:
            handleFrame()

proc loop*() =
    runtime.runGame = true
    when not defined(emscripten):
        while runtime.runGame:
            handleFrame()       
        cleanupResources()
        cleanupTextures()
        cleanupShaders()
        cleanupMeshes()
        cleanupGraphics()
    else:
        emscripten_cancel_main_loop()
        emscripten_set_main_loop(handleFrameWhenEmscripten, 0, 1)
proc render*(scene: Scene) =
    if runtime.engine.primary != scene:
        if isNil(runtime.engine.primary):
            runtime.engine.primary = scene
        else:
            runtime.engine.newPrimary = scene

proc stopLoop*() =
    runtime.runGame = false

proc screen*(width, height: int) =
    settings.screenSize = vec2(width.float32, height.float32)

proc screenToWorldCoord*(pos: Vec2): Vec4 = screenToWorldCoord(
    pos,
    graphics.windowSize, 
    runtime.engine.activeCamera
)

template `camera`*(r: Runtime): CameraComponent = r.engine.activeCamera
template `engine`*(r: Runtime): Engine = r.engine
template `age`*(r: Runtime): float32 = r.age
template `frames`*(r: Runtime): int = r.frames
template `fps`*(r: Runtime): float32 = 1.float32 / r.delta
template `delta`*(r: Runtime): float32 = r.delta
template `input`*(r: Runtime): Input = r.input
template `ratio`*(r: Runtime): float32 = r.engine.ratio
template `windowSize`*(r: Runtime): Vec2 = graphics.windowSize
template `screenSize`*(r: Runtime): Vec2 = graphics.screenSize
template `rayToMousePosition`*(e: Runtime): Ray = getRayToScreenPosition(runtime.camera, getMousePosition(runtime.input))
template `ratio`*(e: Engine): float32 = e.ratio

when defined(android) or defined(ios):
    import ports/linkage_details
    sdlMain()
