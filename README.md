# alasgar
Alasgar is an experimental game engine. The reason behind it was to learn graphic programming using nim programming language.

## OpenGL ES
To make it short, I used opengl es (3.0) because it is easier than Vulkan and also can be ported to android. I hate android, ios and other mobile platforms while they are complex and big.
To just make a small app, you need to download tons of SDKs. But android is open enough and you can make app for it from most of OSs so I will support android. ios is a different story, you need a mac system to build a
hello world app for mobile so I will not port this game engine to apple platforms. If your target is ios, please ignore this engine.

## Do not use this engine
This a basic game engine, and I do not know how long I will maintain it. It is also too much limited so do not use it for production.

## nimx and vmath
I copied most of nimx build system here, just removed and reformed some parts. I will rewrite this part later to use nimble instead of nake. nimx is a UI library (and game framework) for nim, check it out here: https://github.com/yglukhov/nimx

Also most of math stuff copied from vmath: https://github.com/treeform/vmath

## Installation
```bash
nimble install alasgar
```

## Start
```nim
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
# Makes the camera entity child of the scene
addChild(scene, cameraEntity)

# Renders an empty sceene
render(scene)
# Runs game main loop
loop()
```

As you see in code (main.nim), we instantiate a scene, add a camera to it and we render the created scene.
If everything was right, you will see an empty window with the given size. Run it using nim compiler:

```bash
nim c -r main.nim
```

Let us add a cube to our scene.
### First mesh
```nim
...

# Creates cube entity, by default position is 0, 0, 0
var cubeEntity = newEntity(scene, "Cube")
# Add a cube mesh component to entity
addComponent(cubeEntity, newCubeMesh())
# Makes the cube enity child of the scene
addChild(scene, cubeEntity)

...
```

When you run the game barely you can see the cube, as you guess we need to have a light in our scene, let us add a point light to our scene:

### Point light
```nim
...

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

...
```

![](docs/files/cube.jpg)

When you run the code, you will see an ugly grey cube. Let us move the light:

### Scripts
```nim
...

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
    script.transform.positionX = r * sin(engine.age) 
    script.transform.positionZ = r * cos(engine.age)
))
# Makes the light entity child of the scene
addChild(scene, lightEntity)

...
```

![](docs/files/scripts-light-moves.webm)

If you run the code, light is going to move around the cube. As you see in the code we used a anonymous function to change light's position.
You can define a function and use it, here. Feel free to play with nim features.

### Rotation
Let us rotate the cube. To do it we need a script component attached to cube entity:

```nim
...

# Creates cube entity, by default position is 0, 0, 0
var cubeEntity = newEntity(scene, "Cube")
# Add a cube mesh component to entity
addComponent(cubeEntity, newCubeMesh())
# Adds a script component to cube entity
addComponent(cubeEntity, newScriptComponent(proc(script: ScriptComponent, input: Input, delta: float32) =
    # We can rotate an object using euler also we can directly set rotation property that is a quaternion.
    script.transform.euler = vec3(
        sin(engine.age) * sin(engine.age), 
        cos(engine.age), 
        sin(engine.age)
    )
))# Makes the cube enity child of the scene
addChild(scene, cubeEntity)

...
```

![](docs/files/scripts-cube-rotates.webm)


### Material
We can change cube color using material components. We scale cube and make it bigger and then we add a component to define cube material.
I used chroma library to manipulate colors, it is a great library, check here to see how to use it:
https://github.com/treeform/chroma

```nim
...

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
        sin(engine.age) * sin(engine.age), 
        cos(engine.age), 
        sin(engine.age)
    )
))
# Adds a material to cube
addComponent(cubeEntity, newMaterialComponent(diffuseColor=parseHtmlName("olive")))
# Makes the cube enity child of scene
addChild(scene, cubeEntity)

...
```

![](docs/files/cube-diffuse.webm)


### Texture
It is time to give a texture to our cube. To make it multi-platform you need to make "res" folder in you project root and copy your assets inside.
The assets are accessable using a relative path by res like "res://stone-texture.png". It applies to all other assets like obj files or audio files.

```nim
...

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
        sin(engine.age) * sin(engine.age), 
        cos(engine.age), 
        sin(engine.age)
    )
))
# Adds a material to cube
addComponent(cubeEntity, newMaterialComponent(
    diffuseColor=parseHtmlName("white"),
    texture=newTexture("res://stone-texture.png")
    )
)
# Makes the cube enity child of scene
addChild(scene, cubeEntity)

...
```

![](docs/files/cube-texture.webm)

The texture used here grabbed from: https://opengameart.org/content/handpainted-stone-floor-texture

### More lights
As you scene our scene has just one light and the light is moving, let us add a new light to make the scene much clear:

```nim
...

# Creats spot point light entity
var spotLightEntity = newEntity(scene, "SpotLight")
# Sets position to (-6, 6, 6)
spotLightEntity.transform.position = vec3(-6, 6, 6)
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

...
```

![](docs/files/spotpoint-light.gif)
