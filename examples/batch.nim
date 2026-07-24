import std/math

import alasgar

type
  InstanceData = object
    offset: Vec3
    scale: Vec3
    color: Vec4

proc vs(
  IN_POSITION: Layout[0, Vec3],
  IN_UV: Layout[2, Vec2],
  IN_COLOR: Layout[3, Vec4],
  INSTANCE_OFFSET: Batch[4, Vec3],
  INSTANCE_SCALE: Batch[5, Vec3],
  INSTANCE_COLOR: Batch[6, Vec4],
  MODEL: Uniform[Mat4],
  VS_COLOR: var Vec4,
  VS_UV: var Vec2,
) =
  let localPosition = IN_POSITION * INSTANCE_SCALE + INSTANCE_OFFSET
  gl_Position = GLSL_CAMERA.PROJECTION * GLSL_CAMERA.VIEW * MODEL * vec4(localPosition, 1)
  VS_COLOR = IN_COLOR * INSTANCE_COLOR
  VS_UV = IN_UV

proc fs(
  VS_COLOR: Vec4,
  VS_UV: Vec2,
  OUT_COLOR: var Layout[0, Vec4],
) =
  OUT_COLOR = VS_COLOR

const
  TERRAIN_COLUMNS = 256
  TERRAIN_ROWS = 256
  BATCH_COUNT = TERRAIN_COLUMNS * TERRAIN_ROWS
  BAR_SPACING = 0.9'f32
  BAR_WIDTH = 0.45'f32
  MIN_HEIGHT = 0.18'f32
  MAX_HEIGHT = 0.98'f32

var
  cube: Pipeline
  model = Transform()
  camera: Camera
  checker: Texture
  checkerSampler: Sampler
  instances: array[BATCH_COUNT, InstanceData]

proc load() =
  let
    cameraTransform = lookAt(vec3(0.0, 15.0, 24.0), vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0))
    shader = graphics.shader(vs, fs)

  camera = graphics.perspective(cameraTransform, 60, 0.1, 100.0)
  graphics.color = vec4(0.035, 0.04, 0.052, 1.0)

  cube = graphics.compact(graphics.cube(), shader)

proc updateInstances() =
  for i, instance in instances.mpairs:
    let
      row = (i div TERRAIN_COLUMNS).float32
      col = (i mod TERRAIN_COLUMNS).float32
      x = (col - (TERRAIN_COLUMNS.float32 - 1.0) * 0.5) * BAR_SPACING
      z = (row - (TERRAIN_ROWS.float32 - 1.0) * 0.5) * BAR_SPACING
      distance = sqrt(x * x + z * z)
      ripple = sin(distance * 1.15 - runtime.age * 3.2)
      crossWave = cos((x * 0.75 + z * 0.45) + runtime.age * 2.1)
      wave = (ripple + crossWave) * 0.5
      normalized = wave * 0.5 + 0.5
      pulse = 0.15 * sin(runtime.age * 5.0 + row * 0.35 + col * 0.2)
      height = MIN_HEIGHT + (MAX_HEIGHT - MIN_HEIGHT) * (normalized + pulse).clamp(0.0, 1.0)
      red = 0.25 + 0.75 * normalized
      green = 0.35 + 0.45 * (1.0 - abs(wave))
      blue = 0.95 - 0.55 * normalized

    instance.offset = vec3(x, height * 0.5, z)
    instance.scale = vec3(BAR_WIDTH, height, BAR_WIDTH)
    instance.color = vec4(red, green, blue, 1.0)

proc draw() =
  updateInstances()
  cube.shader.set("MODEL", model.world)
  graphics.render(cube, camera, instances)
  graphics.debug()

proc cleanup() =
  destroy(cube)
  destroy(checkerSampler)
  destroy(checker)

window(960, 540, "Batch Draw", load, draw, cleanup)
