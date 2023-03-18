import types

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

proc unpackMaterial*(iMaterial: UVec4, material: var Material) =
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

