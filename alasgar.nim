import sugar
import sequtils
import strutils
import alasgar/core
import alasgar/scene
import alasgar/resources/image
import alasgar/resources/obj
import alasgar/resources/gltf
import alasgar/components/camera
import alasgar/components/catmull
import alasgar/components/interactive
import alasgar/components/collision
import alasgar/components/line
import alasgar/components/light
import alasgar/components/script
import alasgar/components/sprite
import alasgar/components/sound
import alasgar/components/timer
import alasgar/geometry/cube
import alasgar/geometry/grid
import alasgar/geometry/sphere
import alasgar/geometry/plane
import alasgar/engine
import alasgar/logger
import alasgar/utils
import alasgar/system
import alasgar/physics/collision as physics_collision
import alasgar/physics/ray as physics_ray
import alasgar/physics/tools as physics_tools
import alasgar/misc/easing
import alasgar/shaders/base
import alasgar/shaders/compile
import alasgar/shaders/common
import alasgar/effects/fxaa
import alasgar/effects/ssao
import alasgar/effects/hbao
import alasgar/effects/bloom
import alasgar/config
import alasgar/render/gpu
import alasgar/misc/camera as misc_camera


export core,
       system,
       scene,
       image,
       camera,
       line,
       light,
       script,
       sprite,
       sound,
       timer,
       interactive,
       collision,
       cube,
       sphere,
       plane,
       grid,
       obj,
       logger,
       utils,
       color,
       engine,
       physics_collision,
       physics_ray,
       physics_tools,
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
       base,
       compile,
       common,
       fxaa,
       bloom,
       ssao,
       hbao,
       config,
       gpu,
       misc_camera


proc window*(title: string, width, height: int, fullscreen: bool=false, resizable: bool=false) =
    initEngine(
        width,
        height,
        title=title,
        fullscreen=fullscreen,
        resizable=resizable,
    )
