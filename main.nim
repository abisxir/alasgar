import math

import alasgar

var
  logo: Pipeline
  t = Transform(scale:vec3(1.0))
  camera: Camera
  box: Pipeline

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

proc load() =
  logo = graphics.compact(graphics.text.shape("It is a [red]text [white]shape!", transform=translate(vec3(-60, -10, 0))))
  box = graphics.compact(graphics.chamferedBox(bevel=0.2), graphics.shader(vs, fs))
  camera = graphics.perspective(vec3(5, 5, 5), vec3(0, 0, 0), 60, 0.1, 100.0)
  graphics.color = vec4(0.0, 0.0, 0.0, 1.0)

proc draw() =
  let
    speed = 20.0
    r = runtime.age * runtime.delta * speed
  t.rotation = fromEuler(r, r, 0.0)
  logo.shader.set("MODEL", t.world)
  #graphics.render(logo, camera)
  box.shader.set("LIGHT_POSITION", LightPosition)
  box.shader.set("LIGHT_COLOR", LightColor)
  box.shader.set("MODEL", t.world)
  graphics.render(box, camera)
  graphics.debug()

proc cleanup() =
  destroy(logo)

settings.exitOnEscape = true
settings.msaa = 4
window(800, 600, "My Game", load, draw, cleanup)
