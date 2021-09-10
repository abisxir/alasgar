import ../core
import ../utils
import ../system
import ../shader


type
    DirectLightComponent* = ref object of Component
        direction*: Vec3
        color*: Color

    PointLightComponent* = ref object of Component
        color*: Color
        constant*: float32
        linear*: float32
        quadratic*: float32
        intensity*: float32

    SpotPointLightComponent* = ref object of Component
        direction*: Vec3
        color*: Color
        innerLimit*: float32
        outerLimit*: float32
        shadow*: bool

    LightSystem* = ref object of System


proc newPointLightComponent*(color: Color=COLOR_MILK, 
                             constant: float32=1, 
                             linear: float32=0.09, 
                             quadratic: float32=0.032,
                             intensity: float32=1.0): PointLightComponent =
    new(result)
    result.color = color
    result.constant = constant
    result.linear = linear
    result.quadratic = quadratic
    result.intensity = intensity


proc newDirectLightComponent*(direction: Vec3, color: Color=COLOR_WHITE, shadow: bool=false): DirectLightComponent =
    new(result)

    result.direction = direction
    result.color = color


proc newSpotPointLightComponent*(direction: Vec3,
                                 color: Color=COLOR_MILK, 
                                 innerLimit: float32=30, 
                                 outerLimit: float32=45,
                                 shadow: bool=false): SpotPointLightComponent =
    new(result)
    result.direction = direction
    result.color = color
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


method process*(sys: LightSystem, scene: Scene, input: Input, delta: float32) =
    if scene.root != nil:
        # Sets shadow to false
        sys.graphic.shadow.enabled = false

        # Makes a loop on all of shaders
        for shader in sys.graphic.shaders:
            use(shader)

            # Keeps track of available point lights
            var directLightCount = 0
            for c in iterateComponents[DirectLightComponent](scene):
                # Checks that entity is visible
                if c.entity.visible and directLightCount < sys.graphic.maxDirectLights:
                    # Set shader params
                    shader[&"u_direct_lights[{directLightCount}].direction"] = c.direction
                    shader[&"u_direct_lights[{directLightCount}].color"] = c.color.vec3

                    # Increments direct light count
                    inc(directLightCount)

            # Sets direct light amount
            shader["u_direct_lights_count"] = directLightCount

            # Keeps track of available point lights
            var pointLightCount = 0
            for c in iterateComponents[PointLightComponent](scene):
                # Checks that entity is visible
                if c.entity.visible and pointLightCount < sys.graphic.maxPointLights:
                    shader[&"u_point_lights[{pointLightCount}].position"] = c.transform.globalPosition
                    shader[&"u_point_lights[{pointLightCount}].color"] = c.color.vec3
                    shader[&"u_point_lights[{pointLightCount}].constant"] = c.constant
                    shader[&"u_point_lights[{pointLightCount}].linear"] = c.linear
                    shader[&"u_point_lights[{pointLightCount}].quadratic"] = c.quadratic
                    shader[&"u_point_lights[{pointLightCount}].intensity"] = c.intensity 
                    
                    inc(pointLightCount)

            shader["u_point_lights_count"] = pointLightCount

            # Disables shadow
            shader["u_shadow_enabled"] = 0

            # Keeps track of available sopt point lights
            var spotPointLightCount = 0
            for c in iterateComponents[SpotPointLightComponent](scene):
                # Checks that entity is visible
                if c.entity.visible and spotPointLightCount < sys.graphic.maxPointLights:
                    shader[&"u_spotpoint_lights[{spotPointLightCount}].position"] = c.transform.globalPosition
                    shader[&"u_spotpoint_lights[{spotPointLightCount}].color"] = c.color.vec3
                    shader[&"u_spotpoint_lights[{spotPointLightCount}].direction"] = c.direction
                    shader[&"u_spotpoint_lights[{spotPointLightCount}].inner_limit"] = c.innerLimit
                    shader[&"u_spotpoint_lights[{spotPointLightCount}].outer_limit"] = c.outerLimit
                    
                    # Take care of shadow
                    if c.shadow:
                        sys.graphic.shadow.view = c.view
                        sys.graphic.shadow.projection = c.projection
                        sys.graphic.shadow.mvp = c.projection * c.view * identity()
                        sys.graphic.shadow.enabled = true

                        # Enables shadow and updates matrices
                        shader["u_shadow_enabled"] = 1
                        shader["u_shadow_mvp"] = c.projection * c.view * identity()
                        #shader["u_shadow_view_matrix"] = c.view
                        #shader["u_shadow_projection_matrix"] = c.projection
                        #shader["u_shadow_position"] = c.transform.globalPosition

                    inc(spotPointLightCount)

            shader["u_spotpoint_lights_count"] = spotPointLightCount
