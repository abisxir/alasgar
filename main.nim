import alasgar

# Creates a window named Hello
window("Hello", 640, 360)

echo runtime.screenSize
   
# Creates a new scene
var scene = newScene()

# Creates camera entity
var cameraEntity = newEntity(scene, "Camera")
# Sets camera position
cameraEntity.transform.position = vec3(5, 5, 5)
# Adds a perspective camera component to entity
addComponent(
    cameraEntity, 
    newPerspectiveCamera(
        75, 
        runtime.engine.ratio, 
        0.1, 
        100.0, 
        vec3(0) - cameraEntity.transform.position
    )
)
# Makes the camera entity child of the scene
addChild(scene, cameraEntity)

# Creates cube entity, by default position is 0, 0, 0
var model = load("res://glTF-Sample-Models/2.0/Box/glTF-Binary/Box.glb")
var cubeEntity = toEntity(model, scene)
# Makes the cube enity child of the scene
addChild(scene, cubeEntity)


# Creates light entity
var lightEntity = newEntity(scene, "Light")
# Sets light position
lightEntity.transform.position = vec3(-5, 5, 5)
# Adds a point light component to entity
addComponent(
    lightEntity, 
    newPointLightComponent()
)
# Adds a script component to light entity
addComponent(lightEntity, newScriptComponent(proc(script: ScriptComponent) =
    const r = 5 
    # Change position on transform
    script.transform.position = r * vec3(sin(runtime.age), cos(runtime.age), sin(runtime.age) * cos(runtime.age))
))
# Makes the light entity child of the scene
addChild(scene, lightEntity)

# Renders an empty sceene
render(scene)
# Runs game main loop
loop()
