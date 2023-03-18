import sugar
import sequtils
import strutils

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
import alasgar/shader
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
       shader,
       fxaa,
       bloom,
       ssao,
       hbao

type 
    Runtime = ref object
        engine: Engine

var 
    runtime* = Runtime.new
    screenWidth = 0
    screenHeight = 0
    frameLimit = 60
    batchSize = 16 * 1024
    verboseFlag = false
    depthMapSize = vec2(1024)


proc screen*(width, height: int) =
    if runtime.engine != nil:
        quit("Cannot set screen after create window!", -1)
    screenWidth = width
    screenHeight = height

proc window*(title: string, width, height: int, fullscreen: bool=false, resizeable: bool=false) =
    runtime.engine = newEngine(
        width,
        height,
        screenWidth,
        screenHeight,
        title=title,
        fullscreen=fullscreen,
        resizeable=resizeable,
        frameLimit=frameLimit,
        maxBatchSize=batchSize,
        verbose=verboseFlag,
        depthMapSize=depthMapSize,
    )

proc verbose*() = verboseFlag = true
proc limitFrames*(value: int) = frameLimit = value
proc setDepthMapSize*(width, height: int) = depthMapSize = vec2(width.float32, height.float32)
proc render*(scene: Scene) = render(runtime.engine, scene)
proc loop*() = loop(runtime.engine)
proc stopLoop*() = quit(runtime.engine)
proc setMaxBatchSize*(value: int) = batchSize = value
proc screenToWorldCoord*(pos: Vec2): Vec4 = screenToWorldCoord(
    pos,
    runtime.engine.graphic.windowSize, 
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
template `window`*(r: Runtime): Vec2 = r.engine.graphic.windowSize