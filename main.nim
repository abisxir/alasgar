import math

import alasgar
import private/ports/opengl
import private/aljebra
import private/texture


proc vs(
  IN_POSITION: Layout[0, Vec3],
  IN_COLOR: Layout[1, Vec4],
  IN_UV: Layout[2, Vec2],
  MODEL: Uniform[Mat4],
  VS_COLOR: var Vec4,
  VS_UV: var Vec2,
) =
  gl_Position = GLSL_CAMERA.PROJECTION * GLSL_CAMERA.VIEW * MODEL * vec4(IN_POSITION, 1)
  VS_COLOR = IN_COLOR
  VS_UV = IN_UV


proc fs(
  VS_COLOR: Vec4,
  VS_UV: Vec2,
  CHECKER: Uniform[Sampler2D],
  OUT_COLOR: var Layout[0, Vec4]
) =
  OUT_COLOR = VS_COLOR * texture(CHECKER, VS_UV)


const
  VERTICES = [
    # position             color0                uv
    -1.0'f32, -1.0, -1.0,  1.0, 0.0, 0.0, 1.0,  0.0, 0.0,
    1.0, -1.0, -1.0,       1.0, 0.0, 0.0, 1.0,  1.0, 0.0,
    1.0,  1.0, -1.0,       1.0, 0.0, 0.0, 1.0,  1.0, 1.0,
    -1.0,  1.0, -1.0,      1.0, 0.0, 0.0, 1.0,  0.0, 1.0,

    -1.0, -1.0,  1.0,      0.0, 1.0, 0.0, 1.0,  0.0, 0.0,
    1.0, -1.0,  1.0,       0.0, 1.0, 0.0, 1.0,  1.0, 0.0,
    1.0,  1.0,  1.0,       0.0, 1.0, 0.0, 1.0,  1.0, 1.0,
    -1.0,  1.0,  1.0,      0.0, 1.0, 0.0, 1.0,  0.0, 1.0,

    -1.0, -1.0, -1.0,      0.0, 0.0, 1.0, 1.0,  0.0, 0.0,
    -1.0,  1.0, -1.0,      0.0, 0.0, 1.0, 1.0,  1.0, 0.0,
    -1.0,  1.0,  1.0,      0.0, 0.0, 1.0, 1.0,  1.0, 1.0,
    -1.0, -1.0,  1.0,      0.0, 0.0, 1.0, 1.0,  0.0, 1.0,

    1.0, -1.0, -1.0,       1.0, 0.5, 0.0, 1.0,  0.0, 0.0,
    1.0,  1.0, -1.0,       1.0, 0.5, 0.0, 1.0,  1.0, 0.0,
    1.0,  1.0,  1.0,       1.0, 0.5, 0.0, 1.0,  1.0, 1.0,
    1.0, -1.0,  1.0,       1.0, 0.5, 0.0, 1.0,  0.0, 1.0,

    -1.0, -1.0, -1.0,      0.0, 0.5, 1.0, 1.0,  0.0, 0.0,
    -1.0, -1.0,  1.0,      0.0, 0.5, 1.0, 1.0,  1.0, 0.0,
    1.0, -1.0,  1.0,       0.0, 0.5, 1.0, 1.0,  1.0, 1.0,
    1.0, -1.0, -1.0,       0.0, 0.5, 1.0, 1.0,  0.0, 1.0,

    -1.0,  1.0, -1.0,      1.0, 0.0, 0.5, 1.0,  0.0, 0.0,
    -1.0,  1.0,  1.0,      1.0, 0.0, 0.5, 1.0,  1.0, 0.0,
    1.0,  1.0,  1.0,       1.0, 0.0, 0.5, 1.0,  1.0, 1.0,
    1.0,  1.0, -1.0,       1.0, 0.0, 0.5, 1.0,  0.0, 1.0,
  ]
  CHECKER_PIXELS = [
    255'u8, 255, 255, 255,  32, 32, 32, 255,
    32, 32, 32, 255,       255, 255, 255, 255,
  ]
  INDICES = [
    0'u16, 1, 2,  0, 2, 3,
    6, 5, 4,      7, 6, 4,
    8, 9, 10,     8, 10, 11,
    14, 13, 12,   15, 14, 12,
    16, 17, 18,   16, 18, 19,
    22, 21, 20,   23, 22, 20,
  ]

var
  cube: Mesh
  p1 = Transform()
  t1 = Transform(parent: addr p1)
  camera: Camera
  checker: Texture
  checkerSampler: Sampler

proc load() =
  var
    ct = Transform(position: vec3(5, 0, 5))
    shader = graphics.shader(vs, fs)
  ct.lookAt(vec3(0, 0, 0), vec3(0, 1, 0))
  checker = graphics.texture(2, 2, pixels=CHECKER_PIXELS[0].addr)
  checkerSampler = graphics.sampler(checker, minFilter=tfNearest, magFilter=tfNearest)
  cube = graphics.mesh(shader=shader, vertices=VERTICES, indices=INDICES)
  camera = graphics.perspective(ct, 60, 0.1, 100.0)
  graphics.color = vec4(0.0, 0.0, 0.0, 1.0)

proc draw() =
  let
    speed = 20.0
    r = runtime.age * runtime.delta * speed
  p1.position = vec3(2 * sin(runtime.age), 2 * cos(runtime.age), 0)
  t1.rotation = fromEuler(r, r, 0.0)
  cube.shader.set("MODEL", t1.world)
  cube.shader.set("CHECKER", checkerSampler, 0)
  graphics.render(cube, camera)

proc cleanup() =
  destroy(cube)
  destroy(checkerSampler)
  destroy(checker)

window(800, 600, "My Game", load, draw, cleanup)
