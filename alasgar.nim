import sugar
import sequtils
import strutils

import alasgar/private/core
import alasgar/private/resources/image
import alasgar/private/resources/obj
import alasgar/private/resources/gltf
import alasgar/private/components/camera
import alasgar/private/components/interactive
import alasgar/private/components/collision
import alasgar/private/components/line
import alasgar/private/components/light
import alasgar/private/components/environment
import alasgar/private/components/script
import alasgar/private/components/sprite
when not defined(android):
    import alasgar/private/components/sound
import alasgar/private/geometry/cube
import alasgar/private/geometry/grid
import alasgar/private/geometry/sphere
import alasgar/private/geometry/plane
import alasgar/private/engine
import alasgar/private/shader
import alasgar/private/logger
import alasgar/private/utils
import alasgar/private/system
import alasgar/private/physics/collision as physics_collision
import alasgar/private/physics/ray
import alasgar/private/math/helpers
import alasgar/private/math/mat4
import alasgar/private/math/vec2
import alasgar/private/math/vec3
import alasgar/private/math/vec4
import alasgar/private/math/quat
import alasgar/private/animation/easing
import alasgar/private/animation/curve/catmull


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
       shader

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