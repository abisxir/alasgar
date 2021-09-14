![](docs/files/screen-size.gif)

# alasgar
Alasgar is a pure nim game engine based on OpenGL ES. The reason behind it was to learn graphic programming using nim programming language.

# Platforms
 - Linux
 - Windows
 - Android
 - Web (work in progress)
 - Mac (work in progress)
 - iOS (not supoorted)

## Experimental game engine
This is a basic game engine, and it is also too much limited so it is not ready for production use.

## nimx and vmath
I copied most of nimx build system here, just removed and reformed some parts. I will rewrite this part later to use nimble instead of nake. nimx is a UI library (and game framework) for nim, check it out here: https://github.com/yglukhov/nimx

Also most of math stuff copied from vmath: https://github.com/treeform/vmath

## Installation
```bash
nimble install https://github.com/abisxir/alasgar
```

## Quick start
```bash
git clone https://github.com/abisxir/alasgar.git
cd alasgar/examples
nim c -r hello.nim
```

## Window and scene creation
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

As you see, we instantiate a scene, add a camera to it and we render the created scene.
If everything was right, you will see an empty window with the given size. Run it using nim compiler:

```bash
nim c -r main.nim
```

When you create a window by defult it runs in window mode, you can easily enable fullscreen mode:
```nim
# Creates a window named Hello and enables fullscreen mode.
window("Hello", 640, 360, fullscreen=true)
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
To program an entity, we need to add a ScriptComponent to our light entity. Each component has access to entity, entity's transform and component's data.

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
    # Change position on transform
    script.transform.positionX = r * sin(engine.age) 
    script.transform.positionZ = r * cos(engine.age)
))
# Makes the light entity child of the scene
addChild(scene, lightEntity)

...
```

![](docs/files/light-moves.gif)

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

![](docs/files/cube-rotates.gif)


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

![](docs/files/cube-diffuse.gif)


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

![](docs/files/cube-texture.gif)

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

### Access components
Let us dance with light's color, to access a component we can call getComponent[T] on an entity or a component.
We add a script component to our spot light to program it:

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
# Adds a script component to spot point light entity
addComponent(spotLightEntity, newScriptComponent(proc(script: ScriptComponent, input: Input, delta: float32) =
    # Access to point light component, if it returns nil then there is no such a component on this entity.
    let light = getComponent[SpotPointLightComponent](script)
    # Changes light color
    light.color = color(
        abs(sin(engine.age)), 
        abs(cos(engine.age)), 
        abs(sin(engine.age) * sin(engine.age))
    )
))
# Makes the new light child of the scene
addChild(scene, spotLightEntity)

...
```

![](docs/files/light-color-changes.gif)

### Screen size
By default the screen size is equal with window size, but maybe you like to have a lower resolution:
```nim
import alasgar

# Creates a window named Hello, and sets screen size to (160, 90)
screen(160, 90)
window("Hello", 640, 360)

...   
```

You need to specify it before creating window, after window creation there is no effect.

![](docs/files/screen-size.gif)

### Normal maps
It is easy to add a normal map, we need to specify it in material component:

```nim
...

# Adds a material to cube
addComponent(cubeEntity, 
    newMaterialComponent(
        diffuseColor=parseHtmlName("white"),
        texture=newTexture("res://stone-texture.png"),
        normal=newTexture("res://stone-texture-normal.png")
    )
)
# Makes the cube enity child of scene
addChild(scene, cubeEntity)

...
```

![](docs/files/cube-normal.gif)
![normal sample](examples/normal.nim)

### Interactive objects
It is nice if we can select an object with mouse or by touch on mobile platforms, let us add a InteractiveComponent to our cube:

```nim
...

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
        diffuseColor=parseHtmlName("green")
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

...
```

As you see, we have two functions to handle mouse's in and out (hover) functionalities. To make interactive components working, you need to add a collision component.
Alsgar supports just two types, AABB and sphere. We also changed the spot light position, stopped point light moving and set our cube diffuse color to green. It is the final result:

![](docs/files/interactive.gif)
![](examples/interactive.nim)

When you add interactive component, you have: onPress, onRelease, onHover, onOut and onMotion. Except onOut, all of the functions pass collision information.

