import ../glsl

proc vs*(
  IN_POSITION: Layout[0, Vec3],
  IN_UV: Layout[1, Vec2],
  INSTANCE_OFFSET: Batch[2, Vec3],
  INSTANCE_GLYPH: Batch[3, Vec2],
  INSTANCE_COLOR: Batch[4, Vec4],
  MODEL: Uniform[Mat4],
  VS_UV: var Vec2,
  VS_COLOR: var Vec4,
) =
  gl_Position = GLSL_CAMERA.PROJECTION * GLSL_CAMERA.VIEW * MODEL * vec4(IN_POSITION + INSTANCE_OFFSET, 1)
  VS_UV = (INSTANCE_GLYPH + IN_UV) / vec2(16, 8)
  VS_COLOR = INSTANCE_COLOR

proc fs*(
  VS_UV: Vec2,
  VS_COLOR: Vec4,
  ATLAS: Uniform[Sampler2D],
  OUT_COLOR: var Layout[0, Vec4],
) =
  if texture(ATLAS, VS_UV).r < 0.5:
    discard
  OUT_COLOR = VS_COLOR
