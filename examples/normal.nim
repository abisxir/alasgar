import alasgar

# Creates a window named Hello
window("Hello", 640, 360)
   
# Creates a new scene
var scene = newScene()
var env = newEnvironmentComponent()
#enableFog(env, parseHex("121111"), 0.1, 1.0)
setAmbient(env, parseHtmlName("white"), 0.5)
#setBackground(env, parseHex("121111"))
addComponent(scene, env)

# Creates camera entity
var cameraEntity = newEntity(scene, "Camera")
# Sets camera position
cameraEntity.transform.position = vec3(4, 0, 4)
# Adds a perspective camera component to entity
addComponent(
    cameraEntity, 
    newPerspectiveCamera(
        75, 
        engine.ratio, 
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
    newPointLightComponent()
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
addComponent(cubeEntity, newScriptComponent(proc(script: ScriptComponent, input: Input, delta: float32) =
    # We can rotate an object using euler also we can directly set rotation property that is a quaternion.
    script.transform.euler = vec3(
        0, 
        sin(engine.age * 0.1), 
        0
    )
))
# Adds a material to cube
addComponent(
    cubeEntity, 
    newMaterialComponent(
        diffuseColor=parseHtmlName("white"),
        texture=newTexture("res://stone-texture.png"),
        normal=newTexture("res://stone-texture-normal.png")
    )
)
# Makes the cube enity child of scene
addChild(scene, cubeEntity)

# Renders an empty sceene
render(scene)
# Runs game main loop
loop()

