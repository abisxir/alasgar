import alasgar

# Creates a window named Hello
window("Hello", 640, 360)
   
# Creates a new scene
var 
    scene = newScene()
    env = newEnvironmentComponent()

setAmbient(env, parseHtmlName("White"), 0.1)
#setBackground(env, parseHtmlName("Grey"))
#enableFog(env, 0.1, 0.1)
setSkybox(
    env, 
    "res://quarry_03_2k.hdr",
    256
)
setEnvironmentIntensity(env, 0.1)
setSampleCount(env, 2048)
addComponent(scene, env)

# Creates camera entity
var cameraEntity = newEntity(scene, "Camera")
# Sets camera position
cameraEntity.transform.position = vec3(5, 1, 5)
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
# Makes the camera entity child of scene
addChild(scene, cameraEntity)

# Creates light entity
var lightEntity = newEntity(scene, "Light")
lightEntity.transform.scale = vec3(0.1)
# Sets light position
lightEntity.transform.position = vec3(-5, 5, 5)
# Adds a point light component to entity
addComponent(
    lightEntity, 
    newPointLightComponent(
        luminance=10.0
    )
)
addComponent(lightEntity, newSphereMesh())
# Adds a script component to light entity
addComponent(lightEntity, newScriptComponent(proc(script: ScriptComponent, input: Input, delta: float32) =
    const r = 5 
    # Change position on transform
    script.transform.positionX = r * sin(runtime.engine.age) 
    script.transform.positionZ = r * cos(runtime.engine.age)
    script.transform.positionY = 0
))
# Makes the light entity child of the scene
addChild(scene, lightEntity)

# Creates cube entity, by default position is 0, 0, 0
var cubeEntity = newEntity(scene, "Cube")
# Set scale to 3
cubeEntity.transform.scale = vec3(3)
# Add a cube mesh component to entity
addComponent(cubeEntity, newSphereMesh())
# Adds a script component to cube entity
addComponent(cubeEntity, newScriptComponent(proc(script: ScriptComponent, input: Input, delta: float32) =
    # We can rotate an object using euler also we can directly set rotation property that is a quaternion.
    #script.transform.euler = vec3(
    #    sin(runtime.engine.age) * sin(runtime.engine.age), 
    #    cos(runtime.engine.age), 
    #    sin(runtime.engine.age)
    #)
    discard
))
# Adds a material to cube
addComponent(cubeEntity, newPBRMaterialComponent(
    roughness=1.0,
    metallic=1.0,
    ao=1.0,
    specularColor=parseHtmlName("AntiqueWhite"),
    albedoMap=newTexture("res://wood_floor_deck_diff_4k.jpg"),
    normalMap=newTexture("res://wood_floor_deck_nor_gl_4k.jpg"),
    roughnessMap=newTexture("res://wood_floor_deck_arm_4k.jpg"),
    metallicMap=newTexture("res://wood_floor_deck_arm_4k.jpg"),
    aoMap=newTexture("res://wood_floor_deck_arm_4k.jpg"),
))
# Makes the cube enity child of scene
addChild(scene, cubeEntity)

# Renders an empty sceene
render(scene)
# Runs game main loop
loop()

