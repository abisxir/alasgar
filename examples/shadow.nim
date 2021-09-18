import alasgar

# Creates a window named Hello
#screen(480, 270)
window("Hello", 640, 360)
   
# Creates a new scene
var scene = newScene()
# Creates an instance of environment component
var env = newEnvironmentComponent()
# Sets background color to black
setBackground(env, parseHtmlName("DimGray"))
# Enables simple fog effect
enableFog(env, parseHtmlName("DimGray"), 0.05, 1.0)
# Adds environment to our scene
addComponent(scene, env)

# Creates camera entity
var cameraEntity = newEntity(scene, "Camera")
# Sets camera position
cameraEntity.transform.position = vec3(6, 8, 6)
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

# Creates platform entity, by default position is (0, 0, 0)
var platformEntity = newEntity(scene, "Platform")
# Set scale to 20
platformEntity.transform.scale = vec3(20)
platformEntity.transform.euler = vec3(0, 0, -PI / 2)
# Add a cube mesh component to entity
addComponent(platformEntity, newPlaneMesh(1, 1))
# Adds a material to cube
addComponent(
    platformEntity, 
    newMaterialComponent(
        diffuseColor=parseHtmlName("grey"),
        #texture=newTexture("res://stone-texture.png"),
    )
)
# Makes the cube enity child of scene
addChild(scene, platformEntity)

proc createCube(name: string, position: Vec3) =
    # Creates cube entity
    var cubeEntity = newEntity(scene, name)
    # Positions cube to (0, 2, 0)
    cubeEntity.transform.position = position
    # Add a cube mesh component to entity
    addComponent(cubeEntity, newCubeMesh())
    # Adds a script component to cube entity
    addComponent(cubeEntity, newScriptComponent(proc(script: ScriptComponent, input: Input, delta: float32) =
        # We can rotate an object using euler also we can directly set rotation property that is a quaternion.
        script.transform.euler = vec3(
            engine.age * 0.1, 
            engine.age * 0.3, 
            engine.age * 0.2,
        )
    ))
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

createCube("Cube1", vec3(1, 4, 0))
createCube("Cube2", vec3(-4, 2, 0))

# Creats spot point light entity
var spotLightEntity = newEntity(scene, "SpotLight")
# Sets position to (-6, 6, 6)
spotLightEntity.transform.position = vec3(12, 12, 0)
# Adds a spot point light component
addComponent(spotLightEntity, newSpotPointLightComponent(
    vec3(0) - spotLightEntity.transform.position, # Light direction
    color=parseHtmlName("LemonChiffon"),          # Light color
    shadow=true,                                  # Enables shadow
    innerLimit=30,                                # Inner circle of light
    outerLimit=90                                 # Outer circle of light
    )
)
# Makes the new light child of the scene
addChild(scene, spotLightEntity)

# Renders an empty sceene
render(scene)
# Runs game main loop
loop()

