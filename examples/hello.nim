import alasgar

settings.verbose = true
# Creates a window named Hello
window("Hello", 768, 480)
   
# Creates a new scene
var 
    scene = newScene()
    env = newEnvironmentComponent()
setBackground(env, parseHex("f3f3f3"))
addComponent(scene, env)

# Creates camera entity
var 
    cameraEntity = newEntity(scene, "Camera")
# Sets camera position
cameraEntity.transform.position = vec3(5, 5, 5)
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

# Creates light entity
var lightEntity = newEntity(scene, "Light")
# Sets light position
lightEntity.transform.position = vec3(-5, 5, 5)
# Adds a point light component to entity
addComponent(
    lightEntity, 
    newPointLightComponent(
        luminance=200, 
        color=parseHtmlName("white")
    )
)
# Makes the light entity child of the scene
addChild(scene, lightEntity)

# Creates cube entity, by default position is 0, 0, 0
var cubeEntity = newEntity(scene, "Cube")
# Set scale to 2
cubeEntity.transform.scale = vec3(2)
# Add a cube mesh component to entity
addComponent(cubeEntity, newCubeMesh())
# Adds a script component to cube entity
program(cubeEntity, proc(script: ScriptComponent) =
    # We can rotate an object using euler also we can directly set rotation property that is a quaternion.
    script.transform.euler = vec3(
        sin(runtime.age) * cos(runtime.age), 
        cos(runtime.age), 
        sin(runtime.age)
    )
)
addComponent(cubeEntity, newMaterialComponent(
    diffuseColor=parseHtmlName("white"),
    specularColor=parseHtmlName("gray"),
    albedoMap=newTexture("res://stone-texture.png"),
))
# Makes the cube enity child of scene
addChild(scene, cubeEntity)

# Renders an empty sceene
render(scene)
# Runs game main loop
loop()

