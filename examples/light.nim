import alasgar

proc vs(
  IN_POSITION: Layout[0, Vec3],
  IN_NORMAL: Layout[1, Vec3],
  IN_COLOR: Layout[3, Vec4],
  MODEL: Uniform[Mat4],
  VS_POSITION: var Vec3,
  VS_NORMAL: var Vec3,
  VS_COLOR: var Vec4,
) =
  let
    worldPosition = MODEL * vec4(IN_POSITION, 1)
    worldNormal = MODEL * vec4(IN_NORMAL, 0)

  gl_Position = GLSL_CAMERA.PROJECTION * GLSL_CAMERA.VIEW * worldPosition
  VS_POSITION = worldPosition.xyz
  VS_NORMAL = worldNormal.xyz
  VS_COLOR = IN_COLOR

proc fs(
  VS_POSITION: Vec3,
  VS_NORMAL: Vec3,
  VS_COLOR: Vec4,
  LIGHT_POSITION: Uniform[Vec3],
  LIGHT_COLOR: Uniform[Vec3],
  OUT_COLOR: var Layout[0, Vec4],
) =
  let
    normal = normalize(VS_NORMAL)
    lightDirection = normalize(LIGHT_POSITION - VS_POSITION)
    diffuse = max(dot(normal, lightDirection), 0.0)
    brightness = 0.18 + diffuse * 0.82
    color = VS_COLOR.xyz * LIGHT_COLOR * brightness

  OUT_COLOR = vec4(
    color,
    VS_COLOR.w,
  )

const
  LightPosition = vec3(3.0, 4.0, 2.0)
  LightColor = vec3(1.0, 0.92, 0.78)

var
  cube: Pipeline
  camera: Camera
  cubeTransform: Transform

proc constructCamera() =
  camera = graphics.perspective(
    vec3(5.0, 3.5, 6.0),
    vec3(0.0, 0.0, 0.0),
    50.0,
    0.1,
    100.0,
  )


proc load() =
  cube = graphics.compact(
    graphics.cube(color=vec4(0.25, 0.55, 1.0, 1.0)),
    graphics.shader(vs, fs),
  )

  cubeTransform = Transform(position: vec3(0.0, 0.0, 0.0))
  graphics.color = vec4(0.04, 0.05, 0.08, 1.0)

  graphics.onWindowResize(constructCamera)

proc render(pipeline: var Pipeline, model: Mat4) =
  pipeline.shader.set("MODEL", model)
  pipeline.shader.set("LIGHT_POSITION", LightPosition)
  pipeline.shader.set("LIGHT_COLOR", LightColor)
  graphics.render(pipeline, camera)

proc draw() =
  cubeTransform.rotation = fromEuler(0.0, runtime.age * 0.6, 0.0)
  render(cube, cubeTransform.world)

proc cleanup() =
  destroy(cube)

settings.exitOnEscape = true
settings.msaa = 4
window(960, 540, "Basic Light", load, draw, cleanup)
