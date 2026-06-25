import ../glsl

proc vs*(
  IN_POSITION: Layout[0, Vec3],
  IN_UV: Layout[2, Vec2],
  IN_COLOR: Layout[3, Vec4],
  MODEL: Uniform[Mat4],
  VS_COLOR: var Vec4,
  VS_UV: var Vec2,
) =
  gl_Position = GLSL_CAMERA.PROJECTION * GLSL_CAMERA.VIEW * MODEL * vec4(IN_POSITION, 1)
  VS_COLOR = IN_COLOR
  VS_UV = IN_UV

proc fs*(
  VS_COLOR: Vec4,
  VS_UV: Vec2,
  OUT_COLOR: var Layout[0, Vec4]
) =
  OUT_COLOR = VS_COLOR
