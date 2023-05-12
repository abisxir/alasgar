import strformat
import tables
import times
import os

import sdl2

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
import components/environment
import components/skin
import components/animation
import components/catmull
import components/sound
import resources/resource
import shaders/base


when defined(android) or defined(ios):
    import ports/linkage_details
    sdlMain()

type
    Engine* = ref object
        title: string
        primary*: Scene
        scenes*: seq[Scene]
        age: float32
        fps: float32
        frames: float32 
        systems: seq[System]
        ratio: float32
        newPrimary: Scene
        oldPrimary: Scene
        runGame: bool

proc `ratio`*(e: Engine): float32 = e.ratio
proc `age`*(e: Engine): float32 = e.age
proc `fps`*(e: Engine): float32 = e.fps
proc `activeCamera`*(e: Engine): CameraComponent =
    if e.primary != nil:
        e.primary.activeCamera
    else:
        nil

proc addSystem*(engine: Engine, system: System, before: System = nil,
        after: System = nil) =
    if before != nil and contains(engine.systems, before):
        var i = find(engine.systems, before)
        if i + 1 >= len engine.systems:
            add(engine.systems, system)
        else:
            insert(engine.systems, system, i)
    elif after != nil and contains(engine.systems, after):
        var i = find(engine.systems, after) + 1
        if i + 1 >= len engine.systems:
            add(engine.systems, system)
        else:
            insert(engine.systems, system, i)
    else:
        add(engine.systems, system)


proc newEngine*(windowWidth: int,
                windowHeight: int,
                title: string = "Alasgar",
                fullscreen: bool = false,
                resizeable: bool = false): Engine =

    discard sdl2.init(INIT_EVERYTHING)

    echo "* SDL initialized."

    new(result)
    result.title = title

    var flags = SDL_WINDOW_OPENGL or SDL_WINDOW_SHOWN

    if fullscreen: 
        flags = flags or SDL_WINDOW_FULLSCREEN_DESKTOP 
    elif resizeable:
        flags = flags or SDL_WINDOW_RESIZABLE
            
    when defined(ios) or defined(android):
        flags = SDL_WINDOW_OPENGL or SDL_WINDOW_FULLSCREEN
    elif defined(emscripten):
        flags = SDL_WINDOW_OPENGL

    # Initialize SDL windows
    let window = createWindow(
        result.title.cstring,
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        windowWidth.cint,
        windowHeight.cint,
        flags
    )

    echo "* SDL window created!"

    # If the window is fullscreen, specially in mobile devices, window size is going to be perhaps different
    let actualSize = window.getSize()
    result.ratio = actualSize.x.float32 / actualSize.y.float32

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
    addSystem(result, newScriptSystem())
    addSystem(result, newInteractiveSystem())
    addSystem(result, newCatmullSystem())
    addSystem(result, newAnimationSystem())
    addSystem(result, newTraverseSystem())
    addSystem(result, newJointSystem())
    addSystem(result, newSkinSystem())
    addSystem(result, newPrepareSystem())
    addSystem(result, newCameraSystem())
    addSystem(result, newEnvironmentSystem())
    addSystem(result, newSoundSystem())
    addSystem(result, newLightSystem())
    addSystem(result, newRenderSystem())

    for e in result.systems:
        init(e)


proc pushSystem*(engine: Engine, system: System, before: System = nil,
        after: System = nil) =
    insert(engine.systems, system, 0)


proc destroy*(engine: Engine) =
    #if not isNil(engine.primary):
    #    destroy(engine.primary)
    #    engine.primary = nil
    #
    #if len(engine.scenes) > 0:
    #    for scene in engine.scenes:
    #        destroy(scene)
    #    setLen(scene, 0)

    # Cleans systems up
    for e in engine.systems:
        cleanup(e)

    # Finally, quits SDL
    sdl2.quit()


proc loop*(engine: Engine) =
    var
        evt = sdl2.defaultEvent
        age: float32 = 0.0
        frames: int = 0
        lastTicks = epochTime()
        eventProcessTime = 0.0
        systemBenchmark = initTable[string, float]()

    for sys in engine.systems:
        systemBenchmark[sys.name] = 0.float

    engine.runGame = true
    while engine.runGame:
        if not isNil(engine.primary):
            # Cleans up the scene, removes dangling entities
            cleanup(engine.primary)

        # Calculates delta time between current frame and the last drawn frame
        var 
            input: Input
            now = epochTime()
            delta = now - lastTicks
            sleepTime = 0'f32
            frameLimit = if settings.fps > 0: 1'f32 / settings.fps.float32 else: 0'f32

        if delta > 0 and delta < frameLimit:
            sleepTime = frameLimit - delta 
            while sleepTime > 0 and delta < frameLimit:
                sleep(0)
                now = epochTime()
                delta = now - lastTicks
       
        # Updates last tick with the current time
        lastTicks = now

        # Calculates FPS
        engine.fps = 1.float32 / delta
        engine.frames += 1

        # Keeps age of running system
        engine.age += delta
        age += delta
        inc(frames)

        # Updates fps each seconds
        if age >= 1.0:
            age = 0.0
            if settings.verbose:
                logi &"Counted frames: {frames}"
                logi &"FPS: {engine.fps}"
                logi &"  Drawable objects: {len(engine.primary.drawables)}"
                logi &"  Visible objects: {graphics.totalObjects}"
                logi &"  Draw calls: {graphics.drawCalls}"

                var totalSystemTime = 0.float
                for key, value in mpairs(systemBenchmark):
                    logi &"    + {key:<24}: {value}"
                    totalSystemTime += value
                    value = 0.float
                logi &"    + Events                  : {eventProcessTime}"
                logi &"    + Sleep                   : {sleepTime}"
                logi &"    = {delta}"

            frames = 0

        # Marks start of processing events
        let eventStart = epochTime()

        # Set mouse position, even if there is not event.
        updateMousePosition(addr input)        

        # Pulls SDL event and passes to the nodes that need event processing
        while pollEvent(evt):
            if evt.kind == QuitEvent:
                engine.runGame = false
            #elif evt.kind == KeyDown and (evt.evKeyboard.keysym.scancode == SDL_SCANCODE_ESCAPE or evt.evKeyboard.keysym.scancode == SDL_SCANCODE_Q):
            #    runGame = false
            elif evt.kind == WindowEvent:
                var windowEvent = cast[WindowEventPtr](addr(evt))
                if windowEvent.event == WindowEvent_Resized:
                    let width = windowEvent.data1
                    let height = windowEvent.data2
                    graphics.windowSize = vec2(width.float32, height.float32)
                    logi &"Window resized: ({width}, {height})"
            else:
                # Maps SDL event to alasgar event object
                parseEvent(addr evt, graphics.windowSize, addr input)
        
        # Calculates event processing elapsed time 
        eventProcessTime = epochTime() - eventStart

        if isNil(engine.newPrimary):
            # Clear scene
            clear()

            if engine.primary != nil and engine.primary.activeCamera != nil:
                for system in engine.systems:
                    let start = epochTime()
                    process(system, engine.primary, input, delta, engine.frames, engine.age)
                    systemBenchmark[system.name] = epochTime() - start
        else:
            destroy(engine.primary)
            engine.primary = engine.newPrimary
            engine.newPrimary = nil

    cleanupResources()
    cleanupTextures()
    cleanupShaders()
    cleanupMeshes()
    cleanupGraphics()

proc render*(engine: Engine, scene: Scene) =
    if engine.primary != scene:
        if isNil(engine.primary):
            engine.primary = scene
        else:
            engine.newPrimary = scene


proc quit*(engine: Engine) =
    engine.runGame = false