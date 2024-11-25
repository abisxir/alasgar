import compile

export compile

const 
    ALBEDO_MAP_FLAG = 1
    NORMAL_MAP_FLAG = 2
    METALLIC_MAP_FLAG = 4
    ROUGHNESS_MAP_FLAG = 8
    AO_MAP_FLAG = 16
    EMISSIVE_MAP_FLAG = 32

type 
    Camera* = object
        POSITION*: Vec3
        DIRECTION*: Vec3
        VIEW_MATRIX*: Mat4
        INV_VIEW_MATRIX*: Mat4
        PROJECTION_MATRIX*: Mat4
        INV_PROJECTION_MATRIX*: Mat4
        INVERSE_VIEW_PROJECTION_MATRIX*: Mat4
        EXPOSURE*: float
        GAMMA*: float
        NEAR*: float
        FAR*: float
    Environment* = object
        BACKGROUND_COLOR*: Vec4
        AMBIENT_COLOR*: Vec3
        FOG_DENSITY*: float
        FOG_MIN_DISTANCE*: float
        MIP_COUNT*: float
        INTENSITY*: float
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
        BASE_COLOR*: Vec4
        SPECULAR_COLOR*: Vec4
        EMISSIVE_COLOR*: Vec4
        PBR*: Vec4
    Light* = object
        COLOR*: Vec3
        POSITION*: Vec3 
        DIRECTION*: Vec3
        NORMALIZED_DIRECTION*: Vec3
        LUMINANCE*: float 
        RANGE*: float 
        INNER_CUTOFF_COS*: float
        OUTER_CUTOFF_COS*: float
        TYPE*: int
        DEPTH_MAP_LAYER*: int
        SHADOW_MVP*: Mat4
        SHADOW_BIAS*: float
    Fragment* = object
        ALBEDO*: Vec3
        SPECULAR*: Vec3
        BACKGROUND*: Vec3
        AMBIENT*: Vec3
        EMISSIVE*: Vec3
        OPACITY*: float
        PBR*: bool
        METALLIC*: float
        ROUGHNESS*: float
        ALPHA*: float                # ROUGHNESS²
        ALPHA2*: float               # ALPHA²
        ROUGHNESS2_MINUS_ONE*: float # ROUGHNESS² - 1
        NORMALIZED_ROUGHNESS*: float # (ROUGHNESS + 0.5) * 4.0
        K*: float                    # K = (ROUGHNESS + 1)² / 8
        REFLECTANCE*: float
        AO*: float
        SHININESS*: float
        F0*: Vec3
        POSITION*: Vec3
        N*: Vec3
        V*: Vec3
        R*: Vec3
        NoV*: float
        FOG_AMOUNT*: float

proc hasMap(m: Material, flag: int): bool = 
    let flags = uint(round(m.EMISSIVE_COLOR.a * 63.0))
    let r = flags and flag.uint
    result = r == flag.uint

proc getUvChannel(m: Material, flag: int): uint = 
    let flags = uint(round(m.SPECULAR_COLOR.a * 63.0))
    result = flags and flag.uint

template `METALLIC`*(m: Material): float = m.PBR.r
template `ROUGHNESS`*(m: Material): float = m.PBR.g
template `REFLECTANCE`*(m: Material): float = m.PBR.b
template `AO`*(m: Material): float = m.PBR.a
template `HAS_ALBEDO_MAP`*(m: MATERIAL): bool = hasMap(m, ALBEDO_MAP_FLAG)
template `ALBEDO_MAP_UV_CHANNEL`*(m:MATERIAL): uint = getUvChannel(m, ALBEDO_MAP_FLAG)
template `HAS_NORMAL_MAP`*(m: MATERIAL): bool = hasMap(m, NORMAL_MAP_FLAG)
template `NORMAL_MAP_UV_CHANNEL`*(m:MATERIAL): uint = getUvChannel(m, NORMAL_MAP_FLAG)
template `HAS_METALLIC_MAP`*(m: MATERIAL): bool = hasMap(m, METALLIC_MAP_FLAG)
template `METALLIC_MAP_UV_CHANNEL`*(m:MATERIAL): uint = getUvChannel(m, METALLIC_MAP_FLAG)
template `HAS_ROUGHNESS_MAP`*(m: MATERIAL): bool = hasMap(m, ROUGHNESS_MAP_FLAG)
template `ROUGHNESS_MAP_UV_CHANNEL`*(m:MATERIAL): uint = getUvChannel(m, ROUGHNESS_MAP_FLAG)
template `HAS_AO_MAP`*(m: MATERIAL): bool = hasMap(m, AO_MAP_FLAG)
template `AO_MAP_UV_CHANNEL`*(m:MATERIAL): uint = getUvChannel(m, AO_MAP_FLAG)
template `HAS_EMISSIVE_MAP`*(m: MATERIAL): bool = hasMap(m, EMISSIVE_MAP_FLAG)
template `EMISSIVE_MAP_UV_CHANNEL`*(m:MATERIAL): uint = getUvChannel(m, EMISSIVE_MAP_FLAG)
