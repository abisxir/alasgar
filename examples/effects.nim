import alasgar
import alasgar/shaders/common

# Creates a window named Hello
window("Hello", 640, 360)
   
# Creates a new scene
var scene = newScene()
var env = newEnvironmentComponent()
# Sets background color to black
setBackground(env, parseHtmlName("DimGray"))
# Adds environment to our scene
addComponent(scene, env)

# Creates camera entity
var cameraEntity = newEntity(scene, "Camera")
# Sets camera position
cameraEntity.transform.position = vec3(0, 0, 10)
# Creates camera component
var camera = newPerspectiveCamera(
        75, 
        runtime.engine.ratio, 
        0.1, 
        100.0, 
        vec3(0) - cameraEntity.transform.position
    )

# Adds a perspective camera component to entity
addComponent(
    cameraEntity, 
    camera
)
# Split is just for debugging, it will apply it on the second half 
# of the screen when it is 0.5
addEffect(camera, "FXAA", newFxaaEffect(split=0.5))
# Makes the camera entity child of scene
addChild(scene, cameraEntity)

# Creates light entity
var lightEntity = newEntity(scene, "Light")
# Sets light position
lightEntity.transform.position = cameraEntity.transform.position
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
# Adds a material to cube
addComponent(cubeEntity, newMaterialComponent(
    diffuseColor=parseHtmlName("white"),
    albedoMap=newTexture("res://stone-texture.png")
))
# Adds a script component to cube entity
addScript(cubeEntity, proc(script: ScriptComponent) =
    # We can rotate an object using euler also we can directly set rotation property that is a quaternion.
    script.transform.euler = vec3(
        sin(runtime.age) * sin(runtime.age), 
        cos(runtime.age), 
        sin(runtime.age)
    )
)
# Makes the cube enity child of scene
addChild(scene, cubeEntity)

# Creates cube entity, by default position is 0, 0, 0
var gridEntity = newEntity(scene, "Grid")
# Set scale to 2
gridEntity.transform.scale = 10 * vec3(runtime.engine.ratio, 1.0, 1.0)
gridEntity.transform.position = vec3(0, 0, -3)
# Add a cube mesh component to entity
addComponent(gridEntity, newPlaneMesh(1, 1))
# Adds a material to cube
addComponent(gridEntity, newMaterialComponent(
    diffuseColor=parseHtmlName("white"),
))
# Adds a shader to cube
proc fs(COLOR_CHANNEL: Layout[0, Uniform[Sampler2D]], UV: Vec2, COLOR: var Vec4) = COLOR.r = 1.0
addComponent(gridEntity, newFragmentShaderComponent(fs))
# Makes the cube enity child of scene
addChild(scene, gridEntity)


# Creats spot point light entity
var spotLightEntity = newEntity(scene, "SpotLight")
# Sets position to (-6, 6, 6)
spotLightEntity.transform.position = vec3(-6, 6, 6)
# Adds a spot point light component
addComponent(spotLightEntity, newSpotPointLightComponent(
    vec3(0) - spotLightEntity.transform.position, # Light direction
    color=parseHtmlName("aqua"),                  # Light color
    luminance=10.0,                                # Light luminance
    shadow=false,                                 # Casts shadow or not
    innerCutoff=10,                               # Inner circle of light
    outerCutoff=30                                # Outer circle of light
))
# Adds a script component to spot point light entity
addComponent(spotLightEntity, newScriptComponent(proc(script: ScriptComponent) =
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

