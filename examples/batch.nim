import std/math

import alasgar

proc vs(
  IN_POSITION: Layout[0, Vec3],
  IN_NORMAL: Layout[1, Vec3],
  IN_COLOR: Layout[3, Vec4],
  MODEL: Batch[4, Mat4],
  VS_POSITION: var Vec3,
  VS_NORMAL: var Vec3,
  VS_COLOR: var Vec4,
) =
  let
    worldPosition = MODEL * vec4(IN_POSITION, 1.0)
    worldNormal = MODEL * vec4(IN_NORMAL, 0.0)
  gl_Position = GLSL_CAMERA.PROJECTION * GLSL_CAMERA.VIEW * worldPosition
  VS_POSITION = worldPosition.xyz
  VS_NORMAL = normalize(worldNormal.xyz)
  VS_COLOR = IN_COLOR

proc fs(
  VS_POSITION: Vec3,
  VS_NORMAL: Vec3,
  VS_COLOR: Vec4,
  LIGHT_POSITION: Uniform[Vec3],
  OUT_COLOR: var Layout[0, Vec4],
) =
  let
    normal = normalize(VS_NORMAL)
    lightDirection = normalize(LIGHT_POSITION - VS_POSITION)
    diffuse = max(dot(normal, lightDirection), 0.0)
    brightness = 0.1 + diffuse * 0.2
    color = brightness * VS_COLOR.xyz
  OUT_COLOR = vec4(color, 1.0)

const
  TERRAIN_COLUMNS = 96
  TERRAIN_ROWS = 96
  BATCH_COUNT = TERRAIN_COLUMNS * TERRAIN_ROWS
  ACTIVE_COLOR = vec4(0.8, 0.75, 0.75, 1.0)
  ORBIT_SPEED = 1.0
  ORBIT_RADIUS = 6.0
  ORBIT_Y = 12.0
  ORBIT_SCALE = 1.0
  INFLUENCE_RADIUS = 15.0
  BASE_HEIGHT = 0.5

var
  cube, sphere: Pipeline
  camera: Camera
  instances: array[BATCH_COUNT, Mat4]

proc constructCamera() =
  let transform = lookAt(
    vec3(10.0, 30.0, 10.0),
    vec3(0.0, 1.0, 0.0),
    vec3(0.0, 1.0, 0.0),
  )
  camera = graphics.perspective(transform, 58.0, 0.1, 100.0)

proc load() =
  let
    shader = graphics.shader(vs, fs)

  constructCamera()
  graphics.onWindowResize(constructCamera)
  graphics.color = ACTIVE_COLOR

  cube = graphics.compact(graphics.cube(), shader)
  sphere = graphics.compact(graphics.sphere(color=ACTIVE_COLOR))

proc updateInstances(spherePosition: Vec3) =
  for i in instances.low..instances.high:
    let
      column = i mod TERRAIN_COLUMNS
      row = i div TERRAIN_COLUMNS
      x = (column.float32 - (TERRAIN_COLUMNS - 1).float32 * 0.5)
      y = 0.float32
      z = (row.float32 - (TERRAIN_ROWS - 1).float32 * 0.5)

      distance = length(vec2(x - spherePosition.x, z - spherePosition.z))
      influence = 1.0 - smoothstep(0.0, INFLUENCE_RADIUS, distance)
      peak = BASE_HEIGHT + influence * 10 * abs(sin(x * z))
    instances[i] = Transform(position: vec3(x, y, z), scale: vec3(0.5, max(0.5, min(peak, 10.0)), 0.5)).mat4



proc draw() =
  let
    angle = runtime.age * ORBIT_SPEED
    spherePosition = vec3(
      ORBIT_RADIUS * sin(angle),
      ORBIT_Y,
      ORBIT_RADIUS * cos(angle),
    )

  updateInstances(spherePosition)
  cube.shader.set("LIGHT_POSITION", spherePosition)
  graphics.render(cube, camera, instances)
  sphere.shader.set("MODEL", Transform(position: spherePosition).world)
  graphics.render(sphere, camera)
  graphics.debug()

proc cleanup() =
  destroy(cube)
  destroy(sphere)

settings.exitOnEscape = true
settings.msaa = 4
window(960, 540, "Batch Draw", load, draw, cleanup)
