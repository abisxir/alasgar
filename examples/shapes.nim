import std/math

import alasgar

proc vs(
  IN_POSITION: Layout[0, Vec3],
  IN_UV: Layout[2, Vec2],
  IN_COLOR: Layout[3, Vec4],
  MODEL: Uniform[Mat4],
  TINT: Uniform[Vec4],
  VS_COLOR: var Vec4,
  VS_UV: var Vec2,
) =
  gl_Position = GLSL_CAMERA.PROJECTION * GLSL_CAMERA.VIEW * MODEL * vec4(IN_POSITION, 1)
  VS_COLOR = IN_COLOR * TINT
  VS_UV = IN_UV

proc fs(
  VS_COLOR: Vec4,
  VS_UV: Vec2,
  ALBEDO: Uniform[Sampler2D],
  OUT_COLOR: var Layout[0, Vec4],
) =
  OUT_COLOR = VS_COLOR * texture(ALBEDO, VS_UV)

type
  ShapeItem = object
    pipeline: Pipeline
    transform: Transform
    color: Vec4
    spin: Vec3

const
  CHECKER_PIXELS = [
    255'u8, 255, 255, 255,  32, 32, 32, 255,
    32, 32, 32, 255,       255, 255, 255, 255,
  ]

var
  shapes: array[5, ShapeItem]
  camera: Camera
  checkerTexture: Texture
  checkerSampler: Sampler

proc newShape(geometry: Geometry, position, color, spin: Vec3): ShapeItem =
  result.pipeline = graphics.compact(geometry, graphics.shader(vs, fs))
  result.transform = Transform(position: position)
  result.color = vec4(color, 1)
  result.spin = spin

proc constructCamera() =
  let cameraTransform = lookAt(
    vec3(0.0, 0.0, 12.0),
    vec3(0.0, 0.0, 0.0),
    vec3(0.0, 0.0, 0.0)
  )
  camera = graphics.perspective(cameraTransform, 60, 0.1, 100)


proc load() =
  graphics.color = vec4(0.08, 0.09, 0.12, 1)

  checkerTexture = graphics.texture(2, 2, pixels=CHECKER_PIXELS[0].addr)
  checkerSampler = graphics.sampler(checkerTexture, minFilter=tfNearest, magFilter=tfNearest)

  shapes[0] = newShape(graphics.cube(), vec3(-6.0, 0.0, 0.0), vec3(1.0, 0.35, 0.25), vec3(0.8, 1.2, 0.2))
  shapes[1] = newShape(graphics.sphere(), vec3(-3.0, 0.0, 0.0), vec3(0.25, 0.65, 1.0), vec3(0.2, 1.0, 0.8))
  shapes[2] = newShape(graphics.cylinder(), vec3(0.0, 0.0, 0.0), vec3(0.35, 1.0, 0.5), vec3(1.0, 0.3, 0.7))
  shapes[3] = newShape(graphics.torus(), vec3(3.0, 0.0, 0.0), vec3(1.0, 0.8, 0.25), vec3(0.7, 1.1, 0.4))
  shapes[4] = newShape(graphics.plane(), vec3(6.0, 0.0, 0.0), vec3(0.85, 0.45, 1.0), vec3(1.1, 0.4, 0.9))

  constructCamera()
  graphics.onWindowResize(constructCamera)


proc draw() =
  for item in shapes.mitems:
    let spin = item.spin * runtime.age
    item.transform.rotation = fromEuler(spin.x, spin.y, spin.z)
    item.pipeline.shader.set("MODEL", item.transform.world)
    item.pipeline.shader.set("TINT", item.color)
    item.pipeline.shader.set("ALBEDO", checkerSampler, 0)
    graphics.render(item.pipeline, camera)

proc cleanup() =
  for item in shapes.mitems:
    destroy(item.pipeline)
  destroy(checkerSampler)
  destroy(checkerTexture)

settings.exitOnEscape = true
settings.msaa = 4
window(960, 540, "Hello Shapes", load, draw, cleanup)
