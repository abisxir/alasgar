import alasgar/shaders/compile
import alasgar/shaders/types
#import alasgar

proc vertex(CAMERA: Uniform[Camera],
            ENV: Uniform[Environment],
            FRAME: Uniform[Frame],
            MATERIAL: Uniform[Material],
            FAGMENT: Uniform[Fragment],
            gl_Position: var Vec4) =
    gl_Position = vec4(1.0, 0.0, 0.0, 1.0)

proc fragment(COLOR: var Vec4) =
    COLOR = vec4(1.0, 0.0, 0.0, 1.0)

# Creates a window named Hello
#screen(1920, 1080)
#window("Hello", 1920, 1080)

var vs = toGLSL(vertex)
#echo vs
#var fs = toGLSL(fragment)
#echo fs

#[
discard newShader(vs, fs, [])

# Creates a new scene
var scene = newScene()
addComponent(scene, newScriptComponent(proc(script: ScriptComponent, input: Input, delta: float32) =
    if isKeyDown(input, "Escape"):
        stopLoop()
))

# Creates camera entity
var cameraEntity = newEntity(scene, "Camera")
# Sets camera position
cameraEntity.transform.position = vec3(6, 8, 6)
# Adds a perspective camera component to entity
addComponent(
    cameraEntity, 
    newPerspectiveCamera(
        75, 
        runtime.ratio, 
        0.1, 
        100.0, 
        vec3(0) - cameraEntity.transform.position
    )
)
# Makes the camera entity child of scene
addChild(scene, cameraEntity)

# Renders an empty sceene
render(scene)
# Runs game main loop
loop()
]#
