import types
import skin

proc hasFlag(value: uint, flag: int): float =
    let r = value and flag.uint
    if r == flag.uint:
        result = 1.0

const 
    ALBEDO_MAP_FLAG = 1
    NORMAL_MAP_FLAG = 2
    METALLIC_MAP_FLAG = 4
    ROUGHNESS_MAP_FLAG = 8
    AO_MAP_FLAG = 16
    EMISSIVE_MAP_FLAG = 32

proc extractMaterialData(iMaterial: UVec4, material: var Material) =
    let 
        baseColor: Vec4 = unpackUnorm4x8(iMaterial.x)
        specularColor: Vec4 = unpackUnorm4x8(iMaterial.y)
        emissiveColor: Vec4 = unpackUnorm4x8(iMaterial.z)
        unpackedFactors: Vec4 = unpackUnorm4x8(iMaterial.w)
        flags: uint = uint(round(emissiveColor.a * 63.0))
        uv_channels: uint = uint(round(specularColor.a * 63.0))

    material.BASE_COLOR = baseColor.rgb
    material.OPACITY = baseColor.a
    material.SPECULAR_COLOR = specularColor.rgb
    material.EMISSIVE_COLOR = emissiveColor.rgb
    material.METALLIC = unpackedFactors.x
    material.ROUGHNESS = unpackedFactors.y
    material.REFLECTANCE = unpackedFactors.z
    material.AO = unpackedFactors.w

    material.HAS_ALBEDO_MAP = hasFlag(flags, ALBEDO_MAP_FLAG)
    material.ALBEDO_MAP_UV_CHANNEL = hasFlag(uv_channels, ALBEDO_MAP_FLAG)
    material.HAS_NORMAL_MAP = hasFlag(flags, NORMAL_MAP_FLAG)
    material.NORMAL_MAP_UV_CHANNEL = hasFlag(uv_channels, NORMAL_MAP_FLAG)
    material.HAS_METALLIC_MAP = hasFlag(flags, METALLIC_MAP_FLAG)
    material.METALLIC_MAP_UV_CHANNEL = hasFlag(uv_channels, METALLIC_MAP_FLAG)
    material.HAS_ROUGHNESS_MAP = hasFlag(flags, ROUGHNESS_MAP_FLAG)
    material.ROUGHNESS_MAP_UV_CHANNEL = hasFlag(uv_channels, ROUGHNESS_MAP_FLAG)
    material.HAS_AO_MAP = hasFlag(flags, AO_MAP_FLAG)
    material.AO_MAP_UV_CHANNEL = hasFlag(uv_channels, AO_MAP_FLAG)
    material.HAS_EMISSIVE_MAP = hasFlag(flags, EMISSIVE_MAP_FLAG)
    material.EMISSIVE_MAP_UV_CHANNEL = hasFlag(uv_channels, EMISSIVE_MAP_FLAG)


proc calculateUV(uv, sprite: Vec4): Vec2 =
    let
        frameSize = sprite.xy
        frameOffset = sprite.zw
    if frameSize.x > 0.0:
        result = (uv.xy * frameSize) + frameOffset
    else:
        result = uv.xy

proc mainVertex*(iPosition: Layout[0, Vec3], 
                 iNormal: Layout[1, Vec3],
                 iUV: Layout[2, Vec4],
                 iBone: Layout[3, Vec4], 
                 iWeight: Layout[4, Vec4],
                 iModel: Layout[5, Mat4],
                 iMaterial: Layout[9, UVec4],
                 iSprite: Layout[10, Vec4],
                 iSkin: Layout[11, Vec4],
                 uSkinMap: Layout[15, Uniform[Sampler2D]],
                 CAMERA: Uniform[Camera],
                 ENV: Uniform[Environment],
                 FRAME: Uniform[Frame],
                 SURFACE: var Surface,
                 MATERIAL: var Material,
                 gl_Position: var Vec4) =
    
    let
        position = vec4(iPosition, 0)
        model = applySkinTransform(uSkinMap, ENV, iModel, iBone, iWeight, iSkin)

    extractMaterialData(iMaterial, MATERIAL)
    SURFACE.POSITION = model * position
    SURFACE.NORMAL = (model * vec4(iNormal, 0.0)).xyz
    SURFACE.UV = calculateUV(iUV, iSprite)
    SURFACE.POSITION_RELATED_TO_VIEW = CAMERA.VIEW_MATRIX * SURFACE.POSITION
    SURFACE.PROJECTED_POSITION = CAMERA.PROJECTION_MATRIX * SURFACE.POSITION_RELATED_TO_VIEW

    gl_Position = SURFACE.PROJECTED_POSITION


proc mainFragment*(LIGHTS: Uniform[array[64, Light]],
                   CAMERA: Uniform[Camera],
                   ENV: Uniform[Environment],
                   FRAME: Uniform[Frame],
                   SURFACE: Surface,
                   MATERIAL: Material,
                   COLOR: var Layout[0, Vec4],
                   NORMAL: var Layout[0, Vec3]) =
    COLOR.rgb = MATERIAL.BASE_COLOR
    COLOR.a = MATERIAL.OPACITY