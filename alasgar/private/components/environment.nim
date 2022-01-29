import ../core
import ../utils
import ../shader
import ../system
import ../texture

const cubemapCS = staticRead("shaders/environment-cubemap.cs")

type
    EnvironmentComponent* = ref object of Component
        backgroundColor*: Color
        ambientColor*: Color
        fogColor*: Color
        fogDensity*: float32
        fogGradient*: float32
        fogEnabled*: bool
        skybox*: Texture
        #lutMap*: Texture
        #diffuseMap*: Texture
        #specularMap*: Texture

    EnvironmentSystem* = ref object of System


func newEnvironmentComponent*(): EnvironmentComponent =
    new(result)

func setAmbient*(e: EnvironmentComponent, c: Color, intense: float32) =
    e.ambientColor = color(c.r * intense, c.g * intense, c.b * intense)

func enableFog*(e: EnvironmentComponent, color: Color, density, gradient: float32) =
    e.fogEnabled = true
    e.fogColor = color
    e.fogDensity = density
    e.fogGradient = gradient

func setBackground*(env: EnvironmentComponent, c: Color) =
    env.backgroundColor = c

#proc setSkybox*(env: EnvironmentComponent, url: string, size: Vec2) =
#    let texture = newTexture(url)
#    let output = newTexture(size.x, size.y)
#    let shader = newShader(cubemapCS)
#    use(shader)
#    use(texture, 0)


proc setSkybox*(env: EnvironmentComponent, px, nx, py, ny, pz, nz: string) =
    env.skybox = newCubeTexture(px, nx, py, ny, pz, nz)

# System implementation
proc newEnvironmentSystem*(): EnvironmentSystem =
    new(result)
    result.name = "Environment System"


method process*(sys: EnvironmentSystem, scene: Scene, input: Input, delta: float32, frames: float32, age: float32) =
    if scene.root != nil and hasComponent[EnvironmentComponent](scene):
        for shader in sys.graphic.shaders:
            use(shader)
            let env = first[EnvironmentComponent](scene)

            # Sets scene clear color
            sys.graphic.clearColor = env.backgroundColor
            shader["env.clear_color"] = env.ambientColor.vec3

            # Sets scene ambient color
            shader["env.ambient_color"] = env.ambientColor.vec3

            # Sets environment maps
            #use(env.lutMap, 6)
            #use(env.diffuseMap, 7)
            #use(env.specularMap, 8)
            use(env.skybox, 8)

            if env.fogEnabled:
                shader["env.fog_enabled"] = 1
                shader["env.fog_color"] = env.fogColor
                shader["env.fog_density"] = env.fogDensity
                shader["env.fog_gradient"] = env.fogGradient
            else:
                shader["env.fog_enabled"] = 0


