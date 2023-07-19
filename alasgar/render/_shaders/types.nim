import ../../shady

export shady

type 
    Camera* = object
        POSITION*: Vec3
        VIEW_MATRIX*: Mat4
        INV_VIEW_MATRIX*: Mat4
        PROJECTION_MATRIX*: Mat4
        INV_PROJECTION_MATRIX*: Mat4
        EXPOSURE*: float
        GAMMA*: float
        NEAR*: float
        FAR*: float
    Environment* = object
        BACKGROUND_COLOR*: Vec4
        AMBIENT_COLOR*: Vec3
        FOG_DENSITY*: float
        FOG_GRADIENT*: float
        MIP_COUNT*: float
        HAS_ENV_MAP*: int
        LIGHTS_COUNT*: int
        SKIN_SAMPLER_WIDTH*: int
    Frame* = object
        RESOLUTION*: Vec3
        TIME*: float
        TIME_DELTA*: float
        COUNT*: float
        MOUSE*: Vec4
        DATE*: Vec4
    Surface* = object
        POSITION*: Vec4
        POSITION_RELATED_TO_VIEW*: Vec4
        PROJECTED_POSITION*: Vec4
        NORMAL*: Vec3
        UV*: Vec2
    Material* = object
        BASE_COLOR*: Vec3
        SPECULAR_COLOR*: Vec3
        EMISSIVE_COLOR*: Vec3
        OPACITY*: float

        METALLIC*: float
        ROUGHNESS*: float
        REFLECTANCE*: float
        AO*: float

        HAS_ALBEDO_MAP*: float
        HAS_NORMAL_MAP*: float
        HAS_METALLIC_MAP*: float
        HAS_ROUGHNESS_MAP*: float
        HAS_AO_MAP*: float
        HAS_EMISSIVE_MAP*: float

        ALBEDO_MAP_UV_CHANNEL*: float
        NORMAL_MAP_UV_CHANNEL*: float
        METALLIC_MAP_UV_CHANNEL*: float
        ROUGHNESS_MAP_UV_CHANNEL*: float
        AO_MAP_UV_CHANNEL*: float
        EMISSIVE_MAP_UV_CHANNEL*: float
    Light* = object
        COLOR*: Vec3
        POSITION*: Vec3 
        DIRECTION*: Vec3
        NORMALIZED_DIRECTION*: Vec3
        LUMINANCE*: float 
        RANGE*: float 
        INTENSITY*: float
        INNER_CUTOFF_COS*: float
        OUTER_CUTOFF_COS*: float
        TYPE*: int
        DEPTH_MAP_LAYER*: int
        SHADOW_MAP*: Mat4