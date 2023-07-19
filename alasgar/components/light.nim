import ../core
import ../utils
import ../system
import ../shaders/base
import ../render/context
import ../render/gpu
import camera


type
    LightComponent* = ref object of Component
        color*: Color
        luminance*: float32
        shadow: bool
        shadowBias: float32

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
                             luminance=100.0,
                             shadow: bool=false,
                             shadowBias: float32=0.001): PointLightComponent =
    new(result)
    result.color = color
    result.luminance = luminance
    result.shadow = shadow
    result.shadowBias = shadowBias

proc newDirectLightComponent*(direction: Vec3, 
                              color: Color=COLOR_MILK, 
                              luminance: float32=100.0, 
                              shadow: bool=false,
                              shadowBias: float32=0.001): DirectLightComponent =
    new(result)
    result.color = color
    result.luminance = luminance
    result.direction = direction
    result.shadow = shadow
    result.shadowBias = shadowBias

proc newSpotPointLightComponent*(direction: Vec3,
                                 color: Color=COLOR_MILK, 
                                 luminance: float32=50.0,
                                 innerCutoff: float32=30, 
                                 outerCutoff: float32=45,
                                 shadow: bool=false,
                                 shadowBias: float32=0.001): SpotPointLightComponent =
    new(result)
    result.color = color
    result.luminance = luminance
    result.direction = direction
    result.innerCutoff = innerCutoff
    result.outerCutoff = outerCutoff
    result.shadow = shadow
    result.shadowBias = shadowBias

proc getViewMatrix*(light: LightComponent, camera: CameraComponent): Mat4 = 
    if light of SpotPointLightComponent:
        let spot = cast[SpotPointLightComponent](light)
        result = lookAt(spot.transform.globalPosition, spot.transform.globalPosition + spot.direction, VEC3_UP)
    elif light of DirectLightComponent:
        let 
            direct = cast[DirectLightComponent](light)
            depth = 0.25 * (camera.far - camera.near)
            position = camera.transform.globalPosition - depth * normalize(direct.direction)
        result = lookAt(position, direct.direction, VEC3_UP)

proc getProjectionMatrix*(light: LightComponent, camera: CameraComponent): Mat4 = 
    #result = perspective(light.outerLimit, 1, 1, 100)
    if light of SpotPointLightComponent:
        result = perspective(45'f32, 1'f32, camera.near, camera.far)
    elif light of DirectLightComponent:
        result = perspective(90'f32, 1'f32, camera.near, camera.far)


# System implementation
proc newLightSystem*(): LightSystem =
    new(result)
    result.name = "Light System"

proc prepareShadow(camera: CameraComponent, shader: Shader, light: LightComponent, index: int) =
    if light.shadow:
        let 
            view = getViewMatrix(light, camera)
            projection = getProjectionMatrix(light, camera)
            mvp = projection * view
        shader[&"LIGHTS[{index}].SHADOW_MVP"] = mvp
        shader[&"LIGHTS[{index}].SHADOW_BIAS"] = light.shadowBias
        shader[&"LIGHTS[{index}].DEPTH_MAP_LAYER"] = len(graphics.context.shadowCasters)
        add(
            graphics.context.shadowCasters,
            ShadowCaster(
                view: view,
                projection: projection,
                position: light.transform.globalPosition,
                point: light of PointLightComponent,
            )
        )


method process*(sys: LightSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) =
    {.warning[LockLevel]:off.}
    let camera = scene.activeCamera

    if scene.root != nil:
        # Makes a loop on all of shaders
        for shader in graphics.context.shaders:
            use(shader)

            # Keeps track of available point lights
            var lightCount = 0

            for c in iterateComponents[DirectLightComponent](scene):
                # Checks that entity is visible
                if c.entity.visible and lightCount < settings.maxLights:
                    # Set shader params
                    shader[&"LIGHTS[{lightCount}].TYPE"] = ltDirectional.int
                    shader[&"LIGHTS[{lightCount}].COLOR"] = c.color.vec3
                    shader[&"LIGHTS[{lightCount}].LUMINANCE"] = c.luminance
                    shader[&"LIGHTS[{lightCount}].DIRECTION"] = c.direction
                    shader[&"LIGHTS[{lightCount}].NORMALIZED_DIRECTION"] = normalize(c.direction)
                    shader[&"LIGHTS[{lightCount}].DEPTH_MAP_LAYER"] = -1

                    # Takes care of shadow
                    prepareShadow(camera, shader, c, lightCount)

                    # Increments direct light count
                    inc(lightCount)

            for c in iterateComponents[PointLightComponent](scene):
                # Checks that entity is visible
                if c.entity.visible and lightCount < settings.maxLights:
                    shader[&"LIGHTS[{lightCount}].TYPE"] = ltPoint.int
                    shader[&"LIGHTS[{lightCount}].COLOR"] = c.color.vec3
                    shader[&"LIGHTS[{lightCount}].POSITION"] = c.transform.globalPosition
                    shader[&"LIGHTS[{lightCount}].LUMINANCE"] = c.luminance
                    shader[&"LIGHTS[{lightCount}].DEPTH_MAP_LAYER"] = -1
                    
                    inc(lightCount)

            for c in iterateComponents[SpotPointLightComponent](scene):
                # Checks that entity is visible
                if c.entity.visible and lightCount < settings.maxLights:
                    shader[&"LIGHTS[{lightCount}].TYPE"] = ltSpot.int
                    shader[&"LIGHTS[{lightCount}].COLOR"] = c.color.vec3
                    shader[&"LIGHTS[{lightCount}].LUMINANCE"] = c.luminance 
                    shader[&"LIGHTS[{lightCount}].POSITION"] = c.transform.globalPosition
                    shader[&"LIGHTS[{lightCount}].DIRECTION"] = c.direction
                    shader[&"LIGHTS[{lightCount}].NORMALIZED_DIRECTION"] = normalize(c.direction)
                    shader[&"LIGHTS[{lightCount}].INNER_CUTOFF_COS"] = cos(degToRad(c.innerCutoff))
                    shader[&"LIGHTS[{lightCount}].OUTER_CUTOFF_COS"] = cos(degToRad(c.outerCutoff))
                    shader[&"LIGHTS[{lightCount}].DEPTH_MAP_LAYER"] = -1
                    
                    # Takes care of shadow
                    prepareShadow(camera, shader, c, lightCount)

                    inc(lightCount)

            # Sets direct light amount
            shader["ENVIRONMENT.LIGHTS_COUNT"] = lightCount
