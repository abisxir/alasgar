import alasgar

settings.exitOnEsc = true
# Creates a window named Hello
window("Hello", 640, 360)

   
# Creates a new scene
var scene = newScene() 

scene.background = parseHex("d7b1a1")
scene.fogDensity = 0.2
scene.fogDistance = 5

# Creates camera entity
var cameraEntity = newEntity(scene, "Camera")
# Sets camera position
cameraEntity.transform.position = vec3(5, 2, 5)
# Adds a perspective camera component to entity
add(
    cameraEntity, 
    newPerspectiveCamera(
        75, 
        runtime.engine.ratio, 
        0.1, 
        100.0, 
        vec3(0) - cameraEntity.transform.position
    )
)
#addCameraController(cameraEntity)
# Makes the camera entity child of the scene
add(scene, cameraEntity)

cameraEntity[CameraComponent].addEffect("bloom", newBloomEffect())

# Creates cube entity, by default position is 0, 0, 0
#var 
#    model = load("res://glTF-Sample-Models/2.0/BoxAnimated/glTF-Binary/BoxAnimated.glb")
#    cubeEntity = toEntity(model, scene)
#    animator = find[AnimatorComponent](cubeEntity)
#
#for c in clips(animator):
#    echo c
#
#animator.play("anim-1")
#animator.loop = true

var cubeEntity = newEntity(scene, "Cube")
add(cubeEntity, newCubeMesh())
cubeEntity.material.diffuseColor = parseHex("00ff00")
cubeEntity.material.castShadow = true
# Makes the cube enity child of the scene
add(scene, cubeEntity)

var planeEntity = newEntity(scene, "Plane")
add(planeEntity, newPlaneMesh(1, 1))
planeEntity.transform.position = vec3(0, -1, 0)
planeEntity.transform.scale = vec3(100, 1, 100)
planeEntity.material.diffuseColor = parseHex("ff0000")
#planeEntity.material.castShadow = true
add(scene, planeEntity)


# Creates light entity
var lightEntity = newEntity(scene, "Light")
# Sets light position
lightEntity.transform.position = 10 * vec3(1)
# Adds a point light component to entity
add(
    lightEntity, 
    newDirectLightComponent(
        direction=vec3(0) - lightEntity.transform.position,
        luminance=1000.0,
        shadow=true
    )
)
# Adds a script component to light entity
add(lightEntity, newScriptComponent(proc(script: ScriptComponent) =
    const r = 10 
    # Change position on transform
    script.transform.position = r * vec3(sin(runtime.age), 1, cos(runtime.age))
    script[DirectLightComponent].direction = vec3(0) - script.transform.position
    #scene.fogDistance = 0.1 * runtime.age
))
# Makes the light entity child of the scene
add(scene, lightEntity)

# Renders an empty sceene
render(scene)
# Runs game main loop
loop()

