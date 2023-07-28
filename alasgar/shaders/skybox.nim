import types

proc skyboxVertex*(POSITION: Layout[0, Vec3],
                   PROJECTION: Uniform[Mat4],
                   VIEW: Uniform[Mat4],
                   DIRECTION: var Vec3,
                   gl_Position: var Vec4) =
    DIRECTION = POSITION
    gl_Position = PROJECTION * VIEW * vec4(POSITION, 1.0)

proc skyboxFragment*(SKYBOX_MAP: Layout[0, Uniform[SamplerCube]],
                     ENVIRONMENT_INTENSITY: Uniform[float],
                     ENVIRONMENT_BLURRITY: Uniform[float],
                     MIP_COUNT: Uniform[float],
                     DIRECTION: Vec3,
                     COLOR: var Layout[0, Vec4],
                     NORMAL: var Layout[1, Vec4]) =
    COLOR = textureLod(SKYBOX_MAP, normalize(DIRECTION), ENVIRONMENT_BLURRITY * (MIP_COUNT - 1.0)) * ENVIRONMENT_INTENSITY
    NORMAL = vec4(normalize(-DIRECTION), 0.0)
