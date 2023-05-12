import sugar
import sequtils
import strutils

when defined(emscripten):
    import jsbind/emscripten

import alasgar/core
import alasgar/resources/image
import alasgar/resources/obj
import alasgar/resources/gltf
import alasgar/components/camera
import alasgar/components/catmull
import alasgar/components/interactive
import alasgar/components/collision
import alasgar/components/line
import alasgar/components/light
import alasgar/components/environment
import alasgar/components/script
import alasgar/components/sprite
when not defined(android):
    import alasgar/components/sound
import alasgar/geometry/cube
import alasgar/geometry/grid
import alasgar/geometry/sphere
import alasgar/geometry/plane
import alasgar/engine
import alasgar/shaders/base
import alasgar/logger
import alasgar/utils
import alasgar/system
import alasgar/physics/collision as physics_collision
import alasgar/physics/ray
import alasgar/math/helpers
import alasgar/misc/easing
import alasgar/effects/fxaa
import alasgar/effects/ssao
import alasgar/effects/hbao
import alasgar/effects/bloom
import alasgar/config
import alasgar/render/gpu


export core,
       system,
       image,
       camera,
       line,
       environment,
       light,
       script,
       sprite,
       #sound,
       interactive,
       collision,
       physics_collision,
       cube,
       sphere,
       plane,
       grid,
       obj,
       logger,
       utils,
       color,
       engine,
       ray,
       helpers,
       image,
       quat,
       mat4,
       vec2,
       vec3,
       vec4,
       easing,
       catmull,
       sugar,
       sequtils,
       strutils,
       fxaa,
       bloom,
       ssao,
       hbao

type 
    Runtime = ref object
        engine: Engine

var 
    runtime* = Runtime.new


proc screen*(width, height: int) =
    if runtime.engine != nil:
        quit("Cannot set screen after create window!", -1)
    settings.screenSize = vec2(width.float32, height.float32)

proc window*(title: string, width, height: int, fullscreen: bool=false, resizeable: bool=false) =
    runtime.engine = newEngine(
        width,
        height,
        title=title,
        fullscreen=fullscreen,
        resizeable=resizeable,
    )

proc render*(scene: Scene) = render(runtime.engine, scene)
proc innerLoop() {.cdecl.} = loop(runtime.engine)
proc stopLoop*() = quit(runtime.engine)

proc loop*() =
    when defined(emscripten):
        emscripten_set_main_loop(innerLoop, 0, 0)
    else:
        loop(runtime.engine)

proc screenToWorldCoord*(pos: Vec2): Vec4 = screenToWorldCoord(
    pos,
    graphics.windowSize, 
    runtime.engine.activeCamera
)

proc newShaderComponent*(vertexSource, fragmentSource: string): ShaderComponent =
    var instance = newSpatialShader(vertexSource, fragmentSource)
    result = newShaderComponent(instance)

proc newVertexShaderComponent*(source: string): ShaderComponent = newShaderComponent(vertexSource=source, fragmentSource="")
proc newFragmentShaderComponent*(source: string): ShaderComponent = newShaderComponent(vertexSource="", fragmentSource=source)

template `engine`*(r: Runtime): Engine = r.engine
template `age`*(r: Runtime): float32 = r.engine.age
template `ratio`*(r: Runtime): float32 = r.engine.ratio
template `window`*(r: Runtime): Vec2 = graphics.windowSize