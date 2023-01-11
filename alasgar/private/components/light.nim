import ../core
import ../utils
import ../system
import ../shader
import ../render/context


type
    LightComponent* = ref object of Component
        color*: Color
        luminance*: float32
        intensity*: float32
        shadow: bool
        shadowMapSize: Vec2

    DirectLightComponent* = ref object of LightComponent
        direction*: Vec3

    PointLightComponent* = ref object of LightComponent

    SpotPointLightComponent* = ref object of LightComponent
        direction*: Vec3
        innerCutoff*: float32
        outerCutoff*: float32

    LightType* = enum
        ltDirectional = 0
        ltPoint = 1
        ltSpot = 2

    LightSystem* = ref object of System

proc newPointLightComponent*(color: Color=COLOR_MILK, 
                             luminance=1000.0,
                             shadow: bool=false,
                             shadowMapSize: Vec2=vec2(1024, 1024)): PointLightComponent =
    new(result)
    result.color = color
    result.luminance = luminance
    result.intensity = 1.0
    result.shadowMapSize = shadowMapSize
    result.shadow = shadow

proc newDirectLightComponent*(direction: Vec3, 
                              color: Color=COLOR_MILK, 
                              intensity: float32=1.0, 
                              shadow: bool=false,
                              shadowMapSize: Vec2=vec2(1024, 1024)): DirectLightComponent =
    new(result)
    result.color = color
    result.intensity = intensity
    result.direction = direction
    result.shadowMapSize = shadowMapSize
    result.shadow = shadow

proc newSpotPointLightComponent*(direction: Vec3,
                                 color: Color=COLOR_MILK, 
                                 luminance: float32=1000.0,
                                 innerCutoff: float32=30, 
                                 outerCutoff: float32=45,
                                 shadow: bool=false,
                                 shadowMapSize: Vec2=vec2(1024, 1024)): SpotPointLightComponent =
    new(result)
    result.color = color
    result.luminance = luminance
    result.intensity = 1.0
    result.direction = direction
    result.innerCutoff = innerCutoff
    result.outerCutoff = outerCutoff
    result.shadowMapSize = shadowMapSize
    result.shadow = shadow


proc `view`*(light: LightComponent): Mat4 = 
    if light of SpotPointLightComponent:
        let spot = cast[SpotPointLightComponent](light)
        result = lookAt(spot.transform.globalPosition, spot.transform.globalPosition + spot.direction, VEC3_UP)
    elif light of DirectLightComponent:
        let direct = cast[DirectLightComponent](light)
        result = lookAt(direct.direction * 1000 , direct.direction, VEC3_UP)

proc `projection`*(light: LightComponent): Mat4 = 
    #result = perspective(light.outerLimit, 1, 1, 100)
    result = perspective(90, 1, 1, 100)


# System implementation
proc newLightSystem*(): LightSystem =
    new(result)
    result.name = "Light System"

proc prepareShadow(g: Graphic, shader: Shader, light: LightComponent, index: int) =
    if light.shadow:
        shader[&"lights[{index}].shadow_mvp"] = light.projection * light.view * identity()
        shader[&"lights[{index}].depth_map"] = len(g.context.shadowCasters)
        add(
            g.context.shadowCasters,
            ShadowCaster(
                view: light.view,
                projection: light.projection,
                position: light.transform.globalPosition,
                direct: light of DirectLightComponent,
                point: light of PointLightComponent,
                size: light.shadowMapSize,
            )
        )


method process*(sys: LightSystem, scene: Scene, input: Input, delta: float32, frames: float32, age: float32) =
    if scene.root != nil:
        # Makes a loop on all of shaders
        for shader in sys.graphic.context.shaders:
            use(shader)

            # Keeps track of available point lights
            var lightCount = 0

            for c in iterateComponents[DirectLightComponent](scene):
                # Checks that entity is visible
                if c.entity.visible and lightCount < maxLights:
                    # Set shader params
                    shader[&"lights[{lightCount}].type"] = ltDirectional.int
                    shader[&"lights[{lightCount}].color"] = c.color.vec3
                    shader[&"lights[{lightCount}].intensity"] = c.intensity
                    shader[&"lights[{lightCount}].direction"] = c.direction
                    shader[&"lights[{lightCount}].depth_map"] = -1

                    # Increments direct light count
                    inc(lightCount)

            for c in iterateComponents[PointLightComponent](scene):
                # Checks that entity is visible
                if c.entity.visible and lightCount < maxLights:
                    shader[&"lights[{lightCount}].type"] = ltPoint.int
                    shader[&"lights[{lightCount}].color"] = c.color.vec3
                    shader[&"lights[{lightCount}].intensity"] = c.intensity 
                    shader[&"lights[{lightCount}].position"] = c.transform.globalPosition
                    shader[&"lights[{lightCount}].luminance"] = c.luminance
                    shader[&"lights[{lightCount}].depth_map"] = -1
                    
                    inc(lightCount)

            for c in iterateComponents[SpotPointLightComponent](scene):
                # Checks that entity is visible
                if c.entity.visible and lightCount < maxLights:
                    shader[&"lights[{lightCount}].type"] = ltSpot.int
                    shader[&"lights[{lightCount}].color"] = c.color.vec3
                    shader[&"lights[{lightCount}].intensity"] = c.intensity 
                    shader[&"lights[{lightCount}].luminance"] = c.intensity 
                    shader[&"lights[{lightCount}].position"] = c.transform.globalPosition
                    shader[&"lights[{lightCount}].direction"] = c.direction
                    shader[&"lights[{lightCount}].inner_cutoff_cos"] = cos(c.innerCutoff)
                    shader[&"lights[{lightCount}].outer_cutoff_cos"] = cos(c.outerCutoff)
                    shader[&"lights[{lightCount}].depth_map"] = -1
                    
                    # Takes care of shadow
                    prepareShadow(sys.graphic, shader, c, lightCount)

                    inc(lightCount)

            # Sets direct light amount
            shader["env.lights_count"] = lightCount
