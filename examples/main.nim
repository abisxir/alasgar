import alasgar

# Creates a window named Hello
window("Hello", 640, 360)
   
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
# Adds a script component to light entity
addComponent(lightEntity, newScriptComponent(proc(script: ScriptComponent, input: Input, delta: float32) =
    const r = 5 
    # Change position on transform
    script.transform.positionX = r * sin(runtime.age) 
    script.transform.positionZ = r * cos(runtime.age)
))
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
        sin(runtime.age) * sin(runtime.age), 
        cos(runtime.age), 
        sin(runtime.age)
    )
))
# Adds a material to cube
addComponent(cubeEntity, newMaterialComponent(
    diffuseColor=parseHtmlName("white"),
    albedoMap=newTexture("res://stone-texture.png")
    )
)
# Makes the cube enity child of scene
addChild(scene, cubeEntity)


# Creats spot point light entity
var spotLightEntity = newEntity(scene, "SpotLight")
# Sets position to (-6, 6, 6)
spotLightEntity.transform.position = vec3(-6, 6, 6)
# Adds a spot point light component
addComponent(spotLightEntity, newSpotPointLightComponent(
    vec3(0) - spotLightEntity.transform.position, # Light direction
    color=parseHtmlName("aqua"),                            # Light color
    shadow=false,                                 # Casts shadow or not
    innerCutoff=30,                                # Inner circle of light
    outerCutoff=90                                 # Outer circle of light
    )
)
# Adds a script component to spot point light entity
addComponent(spotLightEntity, newScriptComponent(proc(script: ScriptComponent, input: Input, delta: float32) =
    # Access to point light component, if it returns nil then there is no such a component on this entity.
    let light = getComponent[SpotPointLightComponent](script)
    # Changes light color
    light.color = color(
        abs(sin(runtime.age)), 
        abs(cos(runtime.age)), 
        abs(sin(runtime.age) * sin(runtime.age))
    )
))
# Makes the new light child of the scene
addChild(scene, spotLightEntity)


# Renders an empty sceene
render(scene)
# Runs game main loop
loop()

