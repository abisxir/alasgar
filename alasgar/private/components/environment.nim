import ../core
import ../utils
import ../shader
import ../system

type
    EnvironmentComponent* = ref object of Component
        backgroundColor*: Color
        ambientColor*: Color
        fogColor*: Color
        fogDensity*: float32
        fogGradient*: float32
        fogEnabled*: bool

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


# System implementation
proc newEnvironmentSystem*(): EnvironmentSystem =
    new(result)
    result.name = "Environment System"


method process*(sys: EnvironmentSystem, scene: Scene, input: Input,
        delta: float32) =
    if scene.root != nil:
        for shader in sys.graphic.shaders:
            use(shader)

            for c in iterateComponents[EnvironmentComponent](scene):
                sys.graphic.clearColor = c.backgroundColor
                shader[&"u_ambient_color"] = c.ambientColor.vec3
                if c.fogEnabled:
                    shader[&"u_fog_enabled"] = 1
                    shader[&"u_fog_color"] = c.fogColor
                    shader[&"u_fog_density"] = c.fogDensity
                    shader[&"u_fog_gradient"] = c.fogGradient
                else:
                    shader[&"u_fog_enabled"] = 0

                break


