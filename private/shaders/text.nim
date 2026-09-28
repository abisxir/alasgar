import ../shader

proc vs*(
  IN_POSITION: Layout[0, Vec3],
  IN_UV: Layout[1, Vec2],
  INSTANCE_OFFSET: Batch[2, Vec3],
  INSTANCE_GLYPH: Batch[3, Vec2],
  INSTANCE_COLOR: Batch[4, Vec4],
  INSTANCE_SIZE: Batch[5, Vec2],
  MODEL: Uniform[Mat4],
  ATLAS_GRID: Uniform[Vec2],
  VS_UV: var Vec2,
  VS_COLOR: var Vec4,
) =
  gl_Position = GLSL_CAMERA.PROJECTION * GLSL_CAMERA.VIEW * MODEL * vec4(IN_POSITION * vec3(INSTANCE_SIZE.x, INSTANCE_SIZE.y, 1) + INSTANCE_OFFSET, 1)
  VS_UV = (INSTANCE_GLYPH + IN_UV) / ATLAS_GRID
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
