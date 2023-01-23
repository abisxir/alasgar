import alasgar

# Creates a window named Hello
screen(1920, 1080)
window("Hello", 1920, 1080)
   
# Creates a new scene
var scene = newScene()
addComponent(scene, newScriptComponent(proc(script: ScriptComponent, input: Input, delta: float32) =
    if isKeyDown(input, "Escape"):
        stopLoop()
))


# Creates an instance of environment component
var env = newEnvironmentComponent()
# Sets background color to black
setBackground(env, parseHtmlName("DimGray"))
# Enables simple fog effect
enableFog(env, parseHtmlName("DimGray"), 0.05, 1.0)
# Set ambient color
setAmbient(env, parseHtmlName("Olive"), 0.1)
# Adds environment to our scene
addComponent(scene, env)

# Creates camera entity
var cameraEntity = newEntity(scene, "Camera")
# Sets camera position
cameraEntity.transform.position = vec3(0, 5, 5)
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

#[
let rFloor = load("res://floor/scene.gltf")
proc addFloor(position: Vec3) =
    let mFloor = toEntity(rFloor, scene)
    mFloor.transform.euler = vec3(0, 0, -PI / 2)
    mFloor.transform.scale = vec3(2.0)
    mFloor.transform.position = position
    addChild(scene, mFloor)

addFloor(vec3(0, -2, 0))
addFloor(vec3(8, -2, 0))
addFloor(vec3(-8, -2, 0))
addFloor(vec3(0, -2, 8))
addFloor(vec3(0, -2, -8))
addFloor(vec3(8, -2, 8))
addFloor(vec3(-8, -2, -8))
addFloor(vec3(8, -2, -8))
addFloor(vec3(-8, -2, 8))
]#

let platform = newEntity(scene, "Platform")
platform.transform.scale = vec3(10)
platform.transform.euler = vec3(0, 0, -PI / 2)
platform.transform.position = vec3(0, -1, 0)
addComponent(platform, newPlaneMesh(1, 1))
addComponent(platform, newMaterialComponent(
    diffuseColor=parseHtmlName("Beige"),
))
addChild(scene, platform)

proc createCube(name: string, position: Vec3) =
    # Creates cube entity
    var cubeEntity = newEntity(scene, name)
    # Positions cube to (0, 2, 0)
    cubeEntity.transform.position = position
    # Add a cube mesh component to entity
    addComponent(cubeEntity, newCubeMesh())
    # Adds a script component to cube entity
    #addComponent(cubeEntity, newScriptComponent(proc(script: ScriptComponent, input: Input, delta: float32) =
    #    # We can rotate an object using euler also we can directly set rotation property that is a quaternion.
    #    script.transform.euler = vec3(
    #        runtime.age * 0.1, 
    #        runtime.age * 0.3, 
    #        runtime.age * 0.2,
    #    )
    #))
    # Adds a material to cube
    addComponent(
        cubeEntity, 
        newMaterialComponent(
            diffuseColor=parseHtmlName("grey"),
            castShadow=true,
        )
    )
    # Makes the cube enity child of scene
    addChild(scene, cubeEntity)

createCube("Cube1", vec3(0, 0, 0))
#createCube("Cube2", vec3(-4, 2, 0))

proc addLight(position: Vec3) =
    # Creats spot point light entity
    var e = newEntity(scene, "SpotLight")
    # Sets position to (-6, 6, 6)
    e.transform.position = position
    # Adds a spot point light component
    addComponent(e, newSpotPointLightComponent(
        vec3(0) - e.transform.position, # Light direction
        luminance=30.0,
        color=parseHtmlName("LemonChiffon"),          # Light color
        shadow=true,                                  # Enables shadow
        innerCutoff=10,                                # Inner circle of light
        outerCutoff=45                                 # Outer circle of light
        )
    )
    addComponent(e, newScriptComponent(proc(script: ScriptComponent, input: Input, delta: float32) =
        script[SpotPointLightComponent].outerCutoff = 45.0 + 10.0 * sin(runtime.engine.age)
    ))
    # Makes the new light child of the scene
    addChild(scene, e)

addLight(vec3(5, 5, 0))

# Renders an empty sceene
render(scene)
# Runs game main loop
loop()

