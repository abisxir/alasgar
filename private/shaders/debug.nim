import ../glsl

proc vs*(
  IN_POSITION: Layout[0, Vec2],
  IN_COLOR: Layout[1, Vec4],
  VIEW_SIZE: Uniform[Vec2],
  VS_COLOR: var Vec4,
) =
  let ndc = vec2(
    (IN_POSITION.x / VIEW_SIZE.x) * 2.0 - 1.0,
    1.0 - (IN_POSITION.y / VIEW_SIZE.y) * 2.0
  )
  gl_Position = vec4(ndc, 0.0, 1.0)
  VS_COLOR = IN_COLOR

proc fs*(
  VS_COLOR: Vec4,
  OUT_COLOR: var Layout[0, Vec4]
) =
  OUT_COLOR = VS_COLOR
