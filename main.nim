import alasgar

settings.exitOnEsc = true
# Creates a window named Step4
window("Alasgar", 1920, 1080)
   
let 
    # Creates a new scene
    scene = newScene()
    # Creates the camera entity
    cameraEntity = newEntity(scene, "Camera")

# Sets the background color
scene.background = parseHex("909090")

# Sets the camera position
cameraEntity.transform.position = vec3(5, 5, 5)
# Adds a perspective camera component to entity
add(
    cameraEntity, 
    newPerspectiveCamera(
        75, 
        runtime.ratio, 
        0.1, 
        100.0, 
        vec3(0) - cameraEntity.transform.position
    )
)
addCameraController(cameraEntity)
# Makes the camera entity child of the scene
add(scene, cameraEntity)

# Creates the cube entity, by default position is 0, 0, 0
let cubeEntity = newEntity(scene, "Cube")
# Add a cube mesh component to entity
add(cubeEntity, newCubeMesh())
# Adds a script component to the cube entity
program(cubeEntity, proc(script: ScriptComponent) =
    let t = 2 * runtime.age
    # Rotates the cube using euler angles
    script.transform.euler = vec3(
        sin(t),
        cos(t),
        sin(t) * cos(t),
    )
)
# Makes the cube enity child of the scene
#add(scene, cubeEntity)
# Scale it up
#cubeEntity.transform.scale = vec3(2)

# Creates the light entity
let lightEntity = newEntity(scene, "Light")
# Sets light position
lightEntity.transform.position = vec3(4, 5, 4)
# Adds a point light component to entity
add(
    lightEntity, 
    newPointLightComponent()
)
# Makes the light entity child of the scene
add(scene, lightEntity)

let 
    model = load("res://ibm_3278_terminal.glb")
    terminalEntity = toEntity(model, scene)

terminalEntity.transform.position = vec3(0)
terminalEntity.transform.scale = vec3(1.0 / 24.0)
#terminalEntity.transform.rotation = euler(PI, 0, 0)
add(scene, terminalEntity)


# Renders an empty scene
render(scene)
# Runs game main loop
loop()