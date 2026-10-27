import alasgar

proc vs(IN_POSITION: Layout[0, Vec2], POSITION: var Vec2) =
  POSITION = IN_POSITION
  gl_Position = vec4(IN_POSITION, 0, 1)

proc fs(POSITION: Vec2, OUT_COLOR: var Layout[0, Vec4]) =
  let
    p = POSITION * vec2(GLSL_CAMERA.ASPECT, 1)
    pixel = 2.0 / GLSL_CAMERA.SCREEN_SIZE.y
    coverage = 1.0 - smoothstep(0.5 - pixel, 0.5 + pixel, length(p))
  OUT_COLOR = vec4(vec3(coverage), 1)

var
  circle: Pipeline
  camera: Camera

proc load() =
  circle = graphics.pipeline(
    graphics.shader(vs, fs),
    [vec2(-1, -1), vec2(3, -1), vec2(-1, 3)],
    [0'u16, 1, 2]
  )
  camera = graphics.perspective(vec3(0, 0, 1), vec3(0), 60, 0.1, 10)

proc draw() =
  graphics.render(circle, camera)

proc cleanup() =
  destroy(circle)

window(800, 600, "Shader Circle", load, draw, cleanup)
