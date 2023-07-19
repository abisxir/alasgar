import compile
import types
import common
#import skin
#import material
import light
import vertex
import fragment
import ibl


proc mainVertex*(POSITION: Layout[0, Vec3], 
                 NORMAL: Layout[1, Vec3],
                 UV: Layout[2, Vec4],
                 BONE: Layout[3, Vec4], 
                 WEIGHT: Layout[4, Vec4],
                 MODEL: Layout[5, Mat4],
                 MATERIAL_DATA: Layout[9, UVec4],
                 SPRITE: Layout[10, Vec4],
                 SKIN: Layout[11, Vec4],
                 SKIN_MAP: Layout[0, Uniform[Sampler2D]],
                 CAMERA: Uniform[Camera],
                 ENVIRONMENT: Uniform[Environment],
                 FRAME: Uniform[Frame],
                 SURFACE: var Surface,
                 MATERIAL: var Material,
                 gl_Position: var Vec4) =
    
    gl_Position = prepareVertex(
        POSITION, 
        NORMAL,
        UV,
        BONE, 
        WEIGHT,
        MODEL,
        MATERIAL_DATA,
        SPRITE,
        SKIN,
        SKIN_MAP,
        CAMERA,
        ENVIRONMENT,
        FRAME,
        SURFACE,
        MATERIAL
    )


proc mainFragment*(SKIN_MAP: Layout[0, Uniform[Sampler2D]],
                   ALBEDO_MAP: Layout[1, Uniform[Sampler2D]],
                   NORMAL_MAP: Layout[2, Uniform[Sampler2D]],
                   METALLIC_MAP: Layout[3, Uniform[Sampler2D]],
                   ROUGHNESS_MAP: Layout[4, Uniform[Sampler2D]],
                   AO_MAP: Layout[5, Uniform[Sampler2D]],
                   EMISSIVE_MAP: Layout[6, Uniform[Sampler2D]],
                   SKYBOX_MAP: Layout[7, Uniform[SamplerCube]],
                   DEPTH_MAPS: Layout[8, Uniform[Sampler2DArrayShadow]],
                   DEPTH_CUBE_MAPS: Layout[9, Uniform[SamplerCube]],
                   LIGHTS: Uniform[array[64, Light]],
                   CAMERA: Uniform[Camera],
                   ENVIRONMENT: Uniform[Environment],
                   FRAME: Uniform[Frame],
                   SURFACE: Surface,
                   MATERIAL: Material,
                   COLOR: var Layout[0, Vec4],
                   NORMAL: var Layout[1, Vec4]) =
    var FRAGMENT: Fragment = prepareFragment(
            SURFACE, 
            MATERIAL, 
            CAMERA, 
            ENVIRONMENT,
            NORMAL_MAP, 
            ALBEDO_MAP, 
            METALLIC_MAP, 
            ROUGHNESS_MAP, 
            EMISSIVE_MAP, 
            AO_MAP
        )
    
    if FRAGMENT.FOG_AMOUNT < 1.0:
        COLOR.rgb = FRAGMENT.ALBEDO * FRAGMENT.AMBIENT
        COLOR.a = FRAGMENT.OPACITY
        if FRAGMENT.OPACITY <= OPACITY_CUTOFF:
            discard
        else:        
            if ENVIRONMENT.LIGHTS_COUNT > 0:
                for i in 0..<ENVIRONMENT.LIGHTS_COUNT:
                    COLOR.rgb = COLOR.rgb + getLight(LIGHTS[i], FRAGMENT, SURFACE, DEPTH_MAPS)
                COLOR.rgb = COLOR.rgb + FRAGMENT.EMISSIVE
                if ENVIRONMENT.HAS_ENV_MAP > 0:
                    COLOR.rgb = COLOR.rgb + ENVIRONMENT.INTENSITY * getIBL(ENVIRONMENT, FRAGMENT, SKYBOX_MAP)
    
    if FRAGMENT.FOG_AMOUNT > 0.0:
        COLOR = mix(ENVIRONMENT.BACKGROUND_COLOR, COLOR, FRAGMENT.FOG_AMOUNT)

    when defined(DEBUG_ALBEDO):
        COLOR.rgb = vec3(FRAGMENT.ALBEDO)
        COLOR.a = 1.0

    when defined(DEBUG_ROUGHNESS):
        COLOR.rgb = vec3(FRAGMENT.ROUGHNESS)
        COLOR.a = 1.0

    when defined(DEBUG_METALLIC):
        COLOR.rgb = vec3(FRAGMENT.METALLIC)
        COLOR.a = 1.0

    when defined(DEBUG_AO):
        COLOR.rgb = vec3(FRAGMENT.AO)
        COLOR.a = 1.0

    when defined(DEBUG_NORMAL):
        COLOR.rgb = vec3(FRAGMENT.N)
        COLOR.a = 1.0

    when defined(DEBUG_V):
        COLOR.rgb = vec3(FRAGMENT.V)
        COLOR.a = 1.0

    when defined(DEBUG_REFLECTANCE):
        COLOR.rgb = vec3(FRAGMENT.REFLECTANCE)
        COLOR.a = 1.0

    when defined(DEBUG_SHADOW):
        let depth = texture(DEPTH_MAPS, vec4(SURFACE.UV.x, SURFACE.UV.y, 0.0, 0.0))
        COLOR.rgb = vec3(depth)
        COLOR.a = 1.0

    #COLOR.rgb = FRAGMENT.N
    #COLOR.a = 1.0

    NORMAL = vec4(FRAGMENT.N, 0.0)
