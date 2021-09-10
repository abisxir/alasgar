import streams
import sugar
import sequtils
import strutils

import alasgar/private/core
import alasgar/private/image
import alasgar/private/components/camera
import alasgar/private/components/interactive
import alasgar/private/components/collision
import alasgar/private/components/line
import alasgar/private/components/light
import alasgar/private/components/environment
import alasgar/private/components/script
import alasgar/private/components/sprite
#import alasgar/private/components/sound
import alasgar/private/geometry/cube
import alasgar/private/geometry/grid
import alasgar/private/geometry/sphere
import alasgar/private/geometry/plane
import alasgar/private/engine
import alasgar/private/loader/obj
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
       strutils

var mainEngine: Engine
var screenWidth = 0
var screenHeight = 0
var frameLimit = 60
var batchSize = 16 * 1024
var multiSample = 4
var verboseFlag = false
var depthMapSize = vec2(1024, 1024)

proc screen*(width, height: int) =
    if mainEngine != nil:
        quit("Cannot set screen after create window!", -1)
    screenWidth = width
    screenHeight = height

proc window*(title: string, width, height: int, fullscreen: bool=false, resizeable: bool=false) =
    mainEngine = newEngine(
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
proc setMultiSample*(value: int) = multiSample = value
proc render*(scene: Scene) = render(mainEngine, scene)
proc loop*() = loop(mainEngine)
proc stopLoop*() = quit(mainEngine)
proc setMaxBatchSize*(value: int) = batchSize = value
template `screenRatio`*: float32 = mainEngine.ratio
template `engine`*: Engine = mainEngine
template `maxBatchSize`*: int = batchSize
proc screenToWorldCoord*(pos: Vec2): Vec4 = screenToWorldCoord(
    pos,
    mainEngine.graphic.windowSize, 
    mainEngine.activeCamera
)

