import alasgar

proc layout*(e: Entity, level=0) =
    echo spaces(level), "+ ", e.name
    for c in e.components:
        if c of AnimationClipComponent:
            let a = cast[AnimationClipComponent](c)
            echo spaces(level), "  - ", "AnimationClipComponent", a
        elif c of AnimationChannelComponent:
            echo spaces(level), "  - ", "AnimationChannelComponent"
        elif c of SkinComponent:
            echo spaces(level), "  - ", "SkinComponent"
        elif c of JointComponent:
            echo spaces(level), "  - ", "JointComponent"
        elif c of MeshComponent:
            echo spaces(level), "  - ", "MeshComponent"
        else:
            echo spaces(level), "  - ", type(c)
    for child in e.children:
        layout(child, level + 1)

# Creates a window named Hello
#screen(1920, 1080)
window("Hello", 1280, 720)
   
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
#enableFog(env, parseHtmlName("DimGray"), 0.05, 1.0)
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
        runtime.ratio, 
        0.1, 
        100.0, 
        vec3(0) - cameraEntity.transform.position
    )
)
# Makes the camera entity child of scene
addChild(scene, cameraEntity)

# Creates cube entity
var platformEntity = newEntity(scene, "Platform")
# Positions cube to (0, 2, 0)
platformEntity.transform.position = vec3(0, -2, 0)
platformEntity.transform.scale = vec3(10, 0.1, 10)
addComponent(platformEntity, newCubeMesh())
addComponent(
    platformEntity, 
    newMaterialComponent(
        diffuseColor=parseHtmlName("grey"),
        #castShadow=true,
    )
)
addChild(scene, platformEntity)

proc createCube(name: string, position: Vec3) =
    # Creates cube entity
    var cubeEntity = newEntity(scene, name)
    # Positions cube to (0, 2, 0)
    cubeEntity.transform.position = position
    # Add a cube mesh component to entity
    addComponent(cubeEntity, newCubeMesh())
    # Adds a script component to cube entity
    addScript(cubeEntity, proc(script: ScriptComponent, input: Input, delta: float32) =
        # We can rotate an object using euler also we can directly set rotation property that is a quaternion.
        script.transform.euler = vec3(
            runtime.age * 0.1, 
            runtime.age * 0.3, 
            runtime.age * 0.2,
        )
    )
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

proc addLight(position: Vec3) =
    # Creats spot point light entity
    var spotLightEntity = newEntity(scene, "SpotLight")
    # Sets position to (-6, 6, 6)
    spotLightEntity.transform.position = position
    # Adds a spot point light component
    addComponent(spotLightEntity, newSpotPointLightComponent(
        vec3(0) - spotLightEntity.transform.position, # Light direction
        color=parseHtmlName("LemonChiffon"),          # Light color
        shadow=true,                                  # Enables shadow
        innerCutoff=10,                                # Inner circle of light
        outerCutoff=60                                 # Outer circle of light
        )
    )
    # Makes the new light child of the scene
    addChild(scene, spotLightEntity)

addLight(vec3(12, 12, 0))
addLight(vec3(8, 12, 4))

# Renders an empty sceene
render(scene)
# Runs game main loop
loop()

