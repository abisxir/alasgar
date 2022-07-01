import ../core
import ../utils
import ../system
import ../shader
import ../render/depth_buffer


type
    LightComponent* = ref object of Component
        color*: Color
        intensity*: float32
        shadow*: bool
        depthBuffer*: DepthBuffer

    DirectLightComponent* = ref object of LightComponent
        direction*: Vec3

    PointLightComponent* = ref object of LightComponent
        constant*: float32
        linear*: float32
        quadratic*: float32

    SpotPointLightComponent* = ref object of LightComponent
        direction*: Vec3
        innerLimit*: float32
        outerLimit*: float32

    LightType* = enum
        lightTypeDirectional = 0
        lightTypePoint = 1
        lightTypeSpot = 2


    LightSystem* = ref object of System

proc newPointLightComponent*(color: Color=COLOR_MILK, 
                             intensity: float32=1.0,
                             constant: float32=1, 
                             linear: float32=0.0, 
                             quadratic: float32=0.0,
                             shadow: bool=false,
                             shadowMapSize: Vec2=vec2(1024, 1024)): PointLightComponent =
    new(result)
    result.color = color
    result.constant = constant
    result.linear = linear
    result.quadratic = quadratic
    result.intensity = intensity
    result.shadow = shadow
    if result.shadow:
        result.depthBuffer = newDepthBuffer(shadowMapSize)


proc newDirectLightComponent*(direction: Vec3, color: Color=COLOR_MILK, intensity: float32=1.0, shadow: bool=false): DirectLightComponent =
    new(result)
    result.color = color
    result.intensity = intensity
    result.direction = direction


proc newSpotPointLightComponent*(direction: Vec3,
                                 color: Color=COLOR_MILK, 
                                 intensity: float32=1.0,
                                 innerLimit: float32=30, 
                                 outerLimit: float32=45,
                                 shadow: bool=false): SpotPointLightComponent =
    new(result)
    result.color = color
    result.intensity = intensity
    result.direction = direction
    result.innerLimit = innerLimit
    result.outerLimit = outerLimit
    result.shadow = shadow


proc `view`*(light: SpotPointLightComponent): Mat4 = 
    result = lookAt(light.transform.globalPosition, light.transform.globalPosition + light.direction, VEC3_UP)

proc `projection`*(light: SpotPointLightComponent): Mat4 = 
    #result = perspective(light.outerLimit, 1, 1, 100)
    result = perspective(90, 1, 1, 100)


# System implementation
proc newLightSystem*(): LightSystem =
    new(result)
    result.name = "Light System"


method process*(sys: LightSystem, scene: Scene, input: Input, delta: float32, frames: float32, age: float32) =
    if scene.root != nil:
        # Makes a loop on all of shaders
        for shader in sys.graphic.context.shaders:
            use(shader)

            # Keeps track of available point lights
            var lightCount = 0
            for c in iterateComponents[DirectLightComponent](scene):
                # Checks that entity is visible
                if c.entity.visible and lightCount < sys.graphic.maxLights:
                    # Set shader params
                    shader[&"lights[{lightCount}].color"] = c.color
                    shader[&"lights[{lightCount}].intensity"] = c.intensity
                    shader[&"lights[{lightCount}].direction"] = c.direction
                    shader[&"lights[{lightCount}].type"] = lightTypeDirectional.int

                    # Increments direct light count
                    inc(lightCount)

            for c in iterateComponents[PointLightComponent](scene):
                # Checks that entity is visible
                if c.entity.visible and lightCount < sys.graphic.maxLights:
                    shader[&"lights[{lightCount}].color"] = c.color.vec3
                    shader[&"lights[{lightCount}].intensity"] = c.intensity 
                    shader[&"lights[{lightCount}].position"] = c.transform.globalPosition
                    shader[&"lights[{lightCount}].attenuation"] = vec3(c.constant, c.linear, c.quadratic)
                    
                    inc(lightCount)

            for c in iterateComponents[SpotPointLightComponent](scene):
                # Checks that entity is visible
                if c.entity.visible and lightCount < sys.graphic.maxLights:
                    shader[&"lights[{lightCount}].color"] = c.color.vec3
                    shader[&"lights[{lightCount}].intensity"] = c.intensity 
                    shader[&"lights[{lightCount}].position"] = c.transform.globalPosition
                    shader[&"lights[{lightCount}].direction"] = c.direction
                    shader[&"lights[{lightCount}].inner_cone_cos"] = c.innerLimit
                    shader[&"lights[{lightCount}].outer_cone_cos"] = c.outerLimit
                    
                    # Take care of shadow
                    if c.shadow:
                        sys.graphic.shadow.view = c.view
                        sys.graphic.shadow.projection = c.projection
                        sys.graphic.shadow.mvp = c.projection * c.view * identity()
                        sys.graphic.shadow.enabled = true

                        # Enables shadow and updates matrices
                        shader["env.shadow_enabled"] = 1
                        shader["env.shadow_mvp"] = c.projection * c.view * identity()
                        #shader["u_shadow_view_matrix"] = c.view
                        #shader["u_shadow_projection_matrix"] = c.projection
                        #shader["u_shadow_position"] = c.transform.globalPosition

                    inc(lightCount)

            # Sets direct light amount
            shader["env.lights_count"] = lightCount
