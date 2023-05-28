import common
import skin
import material

proc prepareVertex*(POSITION: Vec3, 
                    NORMAL: Vec3,
                    UV: Vec4,
                    BONE: Vec4, 
                    WEIGHT: Vec4,
                    MODEL: Mat4,
                    MATERIAL_DATA: UVec4,
                    SPRITE: Vec4,
                    SKIN: Vec4,
                    SKIN_MAP: Sampler2D,
                    CAMERA: Camera,
                    ENVIRONMENT: Environment,
                    FRAME: Frame,
                    SURFACE: var Surface,
                    MATERIAL: var Material): Vec4 =
    let
        position = vec4(POSITION, 1)
        model = applySkinTransform(SKIN_MAP, ENVIRONMENT, MODEL, BONE, WEIGHT, SKIN)

    unpackMaterial(MATERIAL_DATA, MATERIAL)
    SURFACE.POSITION = model * position
    SURFACE.NORMAL = (model * vec4(NORMAL, 0.0)).xyz
    SURFACE.UV = calculateUV(UV, SPRITE)
    SURFACE.POSITION_RELATED_TO_VIEW = CAMERA.VIEW_MATRIX * SURFACE.POSITION
    SURFACE.PROJECTED_POSITION = CAMERA.PROJECTION_MATRIX * SURFACE.POSITION_RELATED_TO_VIEW

    result = SURFACE.PROJECTED_POSITION
