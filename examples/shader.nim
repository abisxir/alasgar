import alasgar

# Creates a window named Hello
#screen(480, 270)
window("Hello", 1920, 1080)
   
# Creates a new scene
var scene = newScene()
# Creates an instance of environment component
var env = newEnvironmentComponent()
# Sets background color to black
setBackground(env, parseHtmlName("DimGray"))
# Enables simple fog effect
#enableFog(env, 0.1, 1.0)
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
        runtime.engine.ratio, 
        0.1, 
        100.0, 
        vec3(0) - cameraEntity.transform.position
    )
)
# Makes the camera entity child of scene
addChild(scene, cameraEntity)

# Creates platform entity, by default position is (0, 0, 0)
var waterEntity = newEntity(scene, "Water")
# Set scale to 20
waterEntity.transform.scale = vec3(5, 1, 5)
waterEntity.transform.position = vec3(0, 0, 0)
#waterEntity.transform.euler = vec3(0, 0, -PI / 2)
# Add a cube mesh component to entity
#addComponent(waterEntity, newPlaneMesh(1, 1))
addComponent(waterEntity, newCubeMesh())
# Adds a material to cube
addComponent(
    waterEntity, 
    newMaterialComponent(
        diffuseColor=parseHtmlName("Blue"),
        specularColor=parseHtmlName("White"),
        albedoMap=newTexture("res://wave.jpg")
    )
)
addComponent(
    waterEntity,
    newFragmentShaderComponent(""" 
uniform vec4 waterColor;  // color of the water
uniform vec4 reflectionColor;  // color of the reflection

uniform float reflectionSpeed;  // speed of the reflection sine wave
uniform float reflectionAmplitude;  // amplitude of the reflection sine wave
uniform float transparencySpeed;  // speed of the transparency sine wave
uniform float transparencyAmplitude;  // amplitude of the transparency sine wave

vec4 water2() {
  float time = frame.time;
  vec4 water = waterColor;
  vec4 reflection = reflectionColor;

  // compute the reflection color based on a sine wave that oscillates over time
  float reflectionValue = 0.5 + 0.5 * sin(time * reflectionSpeed);
  reflection *= vec4(reflectionValue * reflectionAmplitude);

  // compute the transparency based on a sine wave that oscillates over time
  float transparencyValue = 0.5 + 0.5 * sin(time * transparencySpeed);
  float transparency = transparencyValue * transparencyAmplitude;

  // combine the reflection and water colors
  vec4 color = mix(water, reflection, texture(u_albedo_map, surface.uv * reflectionValue).r);
  //vec4 color = mix(water, reflection, reflectionColor.r);

  // set the alpha channel to the transparency value
  color.a = transparency;

  return color;
}


void fragment() {
    COLOR = water2();
}
""")
)
addComponent(waterEntity, newScriptComponent(proc(script: ScriptComponent, input: Input, delta: float32) =
    let shader = script[ShaderComponent]
    set(shader.instance, "waterColor", parseHtmlName("Blue"))
    set(shader.instance, "reflectionColor", parseHtmlName("White"))
    set(shader.instance, "reflectionSpeed", 5.0)
    set(shader.instance, "reflectionAmplitude", 0.1)
    set(shader.instance, "transparencySpeed", 0.0)
    set(shader.instance, "transparencyAmplitude", 0.5)
))
# Makes the cube enity child of scene
addChild(scene, waterEntity)

proc createCube(name: string, position: Vec3, scale=VEC3_ONE, shadow=true) =
    # Creates cube entity
    var cubeEntity = newEntity(scene, name)
    # Positions cube to (0, 2, 0)
    cubeEntity.transform.position = position
    cubeEntity.transform.scale = scale
    # Add a cube mesh component to entity
    addComponent(cubeEntity, newCubeMesh())
    # Adds a script component to cube entity
    #addComponent(cubeEntity, newScriptComponent(proc(script: ScriptComponent, input: Input, delta: float32) =
    #    # We can rotate an object using euler also we can directly set rotation property that is a quaternion.
    #    script.transform.euler = vec3(
    #        runtime.engine.age * 0.1, 
    #        runtime.engine.age * 0.3, 
    #        runtime.engine.age * 0.2,
    #    )
    #))
    # Adds a material to cube
    addComponent(
        cubeEntity, 
        newMaterialComponent(
            diffuseColor=parseHtmlName("grey"),
            albedoMap=newTexture("res://stone-texture.png"),
            castShadow=shadow,
        )
    )
    # Makes the cube enity child of scene
    addChild(scene, cubeEntity)

createCube("Cube1", vec3(0, -1, 0), vec3(6, 1, 6))
createCube("Cube2", vec3(-6, 0, 0), vec3(1, 1, 5))
createCube("Cube3", vec3(6, 0, 0), vec3(1, 1, 5))
createCube("Cube4", vec3(0, 0, 6), vec3(7, 1, 1))
createCube("Cube4", vec3(0, 0, -6), vec3(7, 1, 1))

# Creats spot point light entity
var directLightEntity = newEntity(scene, "SpotLight")
# Sets position to (-6, 6, 6)
directLightEntity.transform.position = vec3(12, 12, 0)
# Adds a spot point light component
addComponent(directLightEntity, newDirectLightComponent(
    vec3(0) - directLightEntity.transform.position, # Light direction
    color=parseHtmlName("LemonChiffon"),            # Light color
    shadow=true,                                    # Enables shadow
    )
)
# Makes the new light child of the scene
addChild(scene, directLightEntity)

# Renders an empty sceene
render(scene)
# Runs game main loop
loop()

