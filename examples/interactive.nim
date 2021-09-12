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


# Handles mouse hover in
proc onCubeHover(interactive: InteractiveComponent, collision: Collision)=
    let material = getComponent[MaterialComponent](interactive)
    material.diffuseColor = parseHtmlName("yellow")

# Handles mouse hover out
proc onCubeOut(interactive: InteractiveComponent)=
    let material = getComponent[MaterialComponent](interactive)
    material.diffuseColor = parseHtmlName("green")

# Creates cube entity, by default position is 0, 0, 0
var cubeEntity = newEntity(scene, "Cube")
# Set scale to 2
cubeEntity.transform.scale = vec3(2)
# Add a cube mesh component to entity
addComponent(cubeEntity, newCubeMesh())
# Adds a material to cube
addComponent(cubeEntity, 
    newMaterialComponent(
        diffuseColor=parseHtmlName("green"),
        texture=newTexture("res://stone-texture.png")
    )
)
# Adds a collision compnent to cube entity
addComponent(cubeEntity, newCollisionComponent(vec3(-1, -1, -1), vec3(1, 1, 1)))
# Adds an interactive
addComponent(
    cubeEntity, 
    newInteractiveComponent(
        onHover=onCubeHover,
        onOut=onCubeOut
    )
)
# Makes the cube enity child of scene
addChild(scene, cubeEntity)


# Creats spot point light entity
var spotLightEntity = newEntity(scene, "SpotLight")
# Sets position to (-6, 6, 6)
spotLightEntity.transform.position = vec3(6, 6, 6)
# Adds a spot point light component
addComponent(spotLightEntity, newSpotPointLightComponent(
    vec3(0) - spotLightEntity.transform.position, # Light direction
    color=parseHtmlName("aqua"),                            # Light color
    shadow=false,                                 # Casts shadow or not
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
