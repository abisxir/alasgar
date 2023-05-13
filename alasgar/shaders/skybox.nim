import types

proc skyboxVertex*(PROJECTION: Uniform[Mat4],
                   VIEW: Uniform[Mat4],
                   POSITION: Layout[0, Vec3],
                   DIRECTION: var Vec3,
                   gl_Position: var Vec4) =
    DIRECTION = POSITION
    gl_Position = PROJECTION * VIEW * vec4(POSITION, 1.0)

proc skyboxFragment*(SKYBOX: Layout[0, Uniform[SamplerCube]],
                     INVIRONMENT_INTENSITY: Uniform[float],
                     MIP_COUNT: Uniform[float],
                     DIRECTION: Vec3,
                     COLOR: var Vec4) =
    COLOR = textureLod(SKYBOX, normalize(DIRECTION), MIP_COUNT * (1.0 - INVIRONMENT_INTENSITY))