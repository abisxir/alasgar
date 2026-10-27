import ../shader

proc vs*(
  IN_POSITION: Layout[0, Vec3],
  IN_UV: Layout[1, Vec2],
  INSTANCE_OFFSET: Batch[2, Vec3],
  INSTANCE_GLYPH: Batch[3, Vec2],
  INSTANCE_COLOR: Batch[4, Vec4],
  INSTANCE_SIZE: Batch[5, Vec2],
  INSTANCE_SLANT: Batch[6, float32],
  MODEL: Uniform[Mat4],
  ATLAS_GRID: Uniform[Vec2],
  VS_UV: var Vec2,
  VS_COLOR: var Vec4,
) =
  let glyph = IN_POSITION * vec3(INSTANCE_SIZE.x, INSTANCE_SIZE.y, 1)
  gl_Position = GLSL_CAMERA.PROJECTION * GLSL_CAMERA.VIEW * MODEL * vec4(
    glyph.x + glyph.y * INSTANCE_SLANT + INSTANCE_OFFSET.x,
    glyph.y + INSTANCE_OFFSET.y,
    INSTANCE_OFFSET.z,
    1,
  )
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
