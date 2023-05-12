import types

proc hasFlag(value: uint, flag: int): float =
    let r = value and flag.uint
    if r == flag.uint:
        result = 1.0

proc unpackMaterial*(iMaterial: UVec4, material: var Material) =
    let 
        baseColor: Vec4 = unpackUnorm4x8(iMaterial.x)
        specularColor: Vec4 = unpackUnorm4x8(iMaterial.y)
        emissiveColor: Vec4 = unpackUnorm4x8(iMaterial.z)
        unpackedFactors: Vec4 = unpackUnorm4x8(iMaterial.w)
        flags: uint = uint(round(emissiveColor.a * 63.0))
        uv_channels: uint = uint(round(specularColor.a * 63.0))

    material.BASE_COLOR = baseColor
    material.SPECULAR_COLOR = specularColor
    material.EMISSIVE_COLOR = emissiveColor

    material.PBR = unpackedFactors
    #material.METALLIC = unpackedFactors.x
    #material.ROUGHNESS = unpackedFactors.y
    #material.REFLECTANCE = unpackedFactors.z
    #material.AO = unpackedFactors.w

