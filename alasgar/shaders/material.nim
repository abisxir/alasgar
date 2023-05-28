import types

proc unpackMaterial*(iMaterial: UVec4, material: var Material) =
    let 
        baseColor: Vec4 = unpackUnorm4x8(iMaterial.x)
        specularColor: Vec4 = unpackUnorm4x8(iMaterial.y)
        emissiveColor: Vec4 = unpackUnorm4x8(iMaterial.z)
        unpackedFactors: Vec4 = unpackUnorm4x8(iMaterial.w)
        #flags: uint = uint(round(emissiveColor.a * 63.0))
        #uvChannels: uint = uint(round(specularColor.a * 63.0))

    material.BASE_COLOR = baseColor
    material.SPECULAR_COLOR = specularColor
    material.EMISSIVE_COLOR = emissiveColor
    material.PBR = unpackedFactors

