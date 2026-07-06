import std/math

import alasgar

type
  InstanceData = object
    offset: Vec3
    color: Vec4

proc vs(
  IN_POSITION: Layout[0, Vec3],
  IN_UV: Layout[2, Vec2],
  IN_COLOR: Layout[3, Vec4],
  INSTANCE_OFFSET: Batch[4, Vec3],
  INSTANCE_COLOR: Batch[5, Vec4],
  MODEL: Uniform[Mat4],
  VS_COLOR: var Vec4,
  VS_UV: var Vec2,
) =
  gl_Position = GLSL_CAMERA.PROJECTION * GLSL_CAMERA.VIEW * MODEL * vec4(IN_POSITION + INSTANCE_OFFSET, 1)
  VS_COLOR = IN_COLOR * INSTANCE_COLOR
  VS_UV = IN_UV

proc fs(
  VS_COLOR: Vec4,
  VS_UV: Vec2,
  ALBEDO: Uniform[Sampler2D],
  OUT_COLOR: var Layout[0, Vec4],
) =
  OUT_COLOR = VS_COLOR * texture(ALBEDO, VS_UV)

const
  BATCH_COUNT = 1000
  CHECKER_PIXELS = [
    255'u8, 255, 255, 255,  32, 32, 32, 255,
    32, 32, 32, 255,       255, 255, 255, 255,
  ]

var
  cube: Pipeline
  model = Transform()
  camera: Camera
  checker: Texture
  checkerSampler: Sampler
  instances: array[100, InstanceData]

proc load() =
  var
    cameraTransform = Transform(position: vec3(0.0, 0.0, 18.0))
    shader = graphics.shader(vs, fs)

  cameraTransform.lookAt(vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0))
  camera = graphics.perspective(cameraTransform, 60, 0.1, 100.0)
  graphics.color = vec4(0.03, 0.04, 0.06, 1.0)

  checker = graphics.texture(2, 2, pixels=CHECKER_PIXELS[0].addr)
  checkerSampler = graphics.sampler(checker, minFilter=tfNearest, magFilter=tfNearest)
  cube = graphics.compact(graphics.cube(), shader)

proc updateInstances() =
  for i, instance in instances.mpairs:
    let
      row = (i div 10).float32
      col = (i mod 10).float32
      phase = runtime.age + i.float32 * 0.17
      wave = sin(phase) * 0.35
      red = 0.5 + 0.5 * sin(phase)
      green = 0.5 + 0.5 * sin(phase + 2.1)
      blue = 0.5 + 0.5 * sin(phase + 4.2)

    instance.offset = vec3((col - 4.5) * 2.4, (row - 4.5) * 2.4, wave)
    instance.color = vec4(red, green, blue, 1.0)

proc draw() =
  updateInstances()
  model.rotation = fromEuler(runtime.age * 0.25, runtime.age * 0.35, 0.0)
  cube.shader.set("MODEL", model.world)
  cube.shader.set("ALBEDO", checkerSampler, 0)
  graphics.render(cube, camera, instances)

proc cleanup() =
  destroy(cube)
  destroy(checkerSampler)
  destroy(checker)

window(960, 540, "Batch Draw", load, draw, cleanup)
