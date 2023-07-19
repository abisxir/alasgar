import common

proc prepareFragment*(SURFACE: Surface, 
                      MATERIAL: Material,
                      CAMERA: Camera,
                      ENVIRONMENT: Environment,
                      NORMAL_MAP: Sampler2D,
                      ALBEDO_MAP: Sampler2D,
                      METALLIC_MAP: Sampler2D,
                      ROUGHNESS_MAP: Sampler2D,
                      EMISSIVE_MAP: Sampler2D,
                      AO_MAP: Sampler2D): Fragment =
    result.FOG_AMOUNT = getFogAmount(ENVIRONMENT.FOG_DENSITY, SURFACE.POSITION_RELATED_TO_VIEW.xyz)
    if result.FOG_AMOUNT < 1.0:
        if MATERIAL.HAS_ALBEDO_MAP:
            let c = texture(ALBEDO_MAP, SURFACE.UV)
            result.ALBEDO = c.rgb * MATERIAL.BASE_COLOR.rgb
            result.OPACITY = c.a * MATERIAL.BASE_COLOR.a
        else:
            result.ALBEDO = MATERIAL.BASE_COLOR.rgb
            result.OPACITY = MATERIAL.BASE_COLOR.a

        result.BACKGROUND = ENVIRONMENT.BACKGROUND_COLOR.xyz
        result.AMBIENT = ENVIRONMENT.AMBIENT_COLOR.xyz

        if result.OPACITY > OPACITY_CUTOFF:
            result.SPECULAR = MATERIAL.SPECULAR_COLOR.rgb

            if MATERIAL.HAS_AO_MAP and MATERIAL.AO > 0.0:
                result.AO = MATERIAL.AO * texture(AO_MAP, SURFACE.UV).r
            else:
                result.AO = MATERIAL.AO

            if MATERIAL.HAS_ROUGHNESS_MAP and MATERIAL.ROUGHNESS > 0.0:
                result.ROUGHNESS = MATERIAL.ROUGHNESS * texture(ROUGHNESS_MAP, SURFACE.UV).g
            else:
                result.ROUGHNESS = MATERIAL.ROUGHNESS

            if MATERIAL.HAS_METALLIC_MAP and MATERIAL.METALLIC > 0.0:
                result.METALLIC = MATERIAL.METALLIC * texture(METALLIC_MAP, SURFACE.UV).b
            else:
                result.METALLIC = MATERIAL.METALLIC

            if MATERIAL.HAS_EMISSIVE_MAP:
                result.EMISSIVE = texture(EMISSIVE_MAP, SURFACE.UV).rgb
            else:
                result.EMISSIVE = MATERIAL.EMISSIVE_COLOR.rgb

            result.POSITION = SURFACE.POSITION.xyz / SURFACE.POSITION.w
            if MATERIAL.HAS_NORMAL_MAP:
                result.N = getNormalMap(result.POSITION, SURFACE.NORMAL, SURFACE.UV, NORMAL_MAP)
            else:
                result.N = SURFACE.NORMAL
            result.V = normalize(CAMERA.POSITION - result.POSITION)
            result.R = normalize(reflect(-result.V, result.N))
            result.NoV = max(dot(result.N, result.V), EPSILON)

            if isPBR(result):
                result.ALPHA = result.ROUGHNESS * result.ROUGHNESS
                result.ALPHA2 = result.ALPHA * result.ALPHA
                result.ROUGHNESS2_MINUS_ONE = result.ALPHA2 - 1.0
                result.K = pow2(result.ROUGHNESS + 1.0) / 8.0
                result.NORMALIZED_ROUGHNESS = (result.ROUGHNESS + 0.5) * 4.0
                result.REFLECTANCE = MATERIAL.REFLECTANCE
                result.F0 = mix(vec3(0.04 * result.REFLECTANCE * result.REFLECTANCE), result.ALBEDO, result.METALLIC)
                result.ALBEDO = result.ALBEDO * (1.0 - 0.04) * (1.0 - result.METALLIC)
                #result.F0 = result.METALLIC * result.ALBEDO + 0.16 * result.REFLECTANCE * result.REFLECTANCE * (1.0 - result.METALLIC)
                #result.F = mix(result.ALBEDO * (1.0 - result.F0), vec3(0), result.METALLIC)
            else:
                result.SHININESS = MATERIAL.REFLECTANCE * 255.0
                result.F0 = mix(vec3(0.04 * result.REFLECTANCE * result.REFLECTANCE), result.ALBEDO, 1.0 - result.REFLECTANCE)
