import alasgar

settings.exitOnEsc = true
# Creates a window named Hello
window("Hello", 640, 360)

   
# Creates a new scene
var scene = newScene() 
#scene.background = parseHex("ff00ff")

# Creates camera entity
var cameraEntity = newEntity(scene, "Camera")
# Sets camera position
cameraEntity.transform.position = vec3(5, 5, 5)
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
# Makes the camera entity child of the scene
add(scene, cameraEntity)

cameraEntity[CameraComponent].addEffect("bloom", newBloomEffect())

# Creates cube entity, by default position is 0, 0, 0
var 
    model = load("res://glTF-Sample-Models/2.0/BoxAnimated/glTF-Binary/BoxAnimated.glb")
    cubeEntity = toEntity(model, scene)
    animator = find[AnimatorComponent](cubeEntity)

for c in clips(animator):
    echo c

animator.play("anim-1")
animator.loop = true

cubeEntity.material.diffuseColor = parseHex("00ff00")
# Makes the cube enity child of the scene
add(scene, cubeEntity)


# Creates light entity
var lightEntity = newEntity(scene, "Light")
# Sets light position
lightEntity.transform.position = 10 * vec3(1)
# Adds a point light component to entity
add(
    lightEntity, 
    newPointLightComponent(
        luminance=20
    )
)
# Adds a script component to light entity
add(lightEntity, newScriptComponent(proc(script: ScriptComponent) =
    const r = 5 
    # Change position on transform
    script.transform.position = r * vec3(sin(runtime.age), cos(runtime.age), sin(runtime.age) * cos(runtime.age))
))
# Makes the light entity child of the scene
add(scene, lightEntity)

# Renders an empty sceene
render(scene)
# Runs game main loop
loop()

