import math

import alasgar
import private/ports/opengl
import private/aljebra

proc vertex(
  IN_POSITION: Layout[0, Vec3],
  IN_COLOR: Layout[1, Vec4],
  MODEL: Uniform[Mat4],
  COLOR: var Vec4,
  gl_Position: var Vec4
) =
  gl_Position = GLSL_CAMERA.PROJECTION * GLSL_CAMERA.VIEW * MODEL * vec4(IN_POSITION, 1)
  COLOR = IN_COLOR


proc fragment(
  COLOR: Vec4,
  OUT_COLOR: var Layout[0, Vec4]
) =
  OUT_COLOR = COLOR


const
  VERTICES = [
    # position             color0
    -1.0'f32, -1.0, -1.0,  1.0, 0.0, 0.0, 1.0,
    1.0, -1.0, -1.0,      1.0, 0.0, 0.0, 1.0,
    1.0,  1.0, -1.0,      1.0, 0.0, 0.0, 1.0,
    -1.0,  1.0, -1.0,      1.0, 0.0, 0.0, 1.0,

    -1.0, -1.0,  1.0,      0.0, 1.0, 0.0, 1.0,
    1.0, -1.0,  1.0,      0.0, 1.0, 0.0, 1.0,
    1.0,  1.0,  1.0,      0.0, 1.0, 0.0, 1.0,
    -1.0,  1.0,  1.0,      0.0, 1.0, 0.0, 1.0,

    -1.0, -1.0, -1.0,      0.0, 0.0, 1.0, 1.0,
    -1.0,  1.0, -1.0,      0.0, 0.0, 1.0, 1.0,
    -1.0,  1.0,  1.0,      0.0, 0.0, 1.0, 1.0,
    -1.0, -1.0,  1.0,      0.0, 0.0, 1.0, 1.0,

    1.0, -1.0, -1.0,      1.0, 0.5, 0.0, 1.0,
    1.0,  1.0, -1.0,      1.0, 0.5, 0.0, 1.0,
    1.0,  1.0,  1.0,      1.0, 0.5, 0.0, 1.0,
    1.0, -1.0,  1.0,      1.0, 0.5, 0.0, 1.0,

    -1.0, -1.0, -1.0,      0.0, 0.5, 1.0, 1.0,
    -1.0, -1.0,  1.0,      0.0, 0.5, 1.0, 1.0,
    1.0, -1.0,  1.0,      0.0, 0.5, 1.0, 1.0,
    1.0, -1.0, -1.0,      0.0, 0.5, 1.0, 1.0,

    -1.0,  1.0, -1.0,      1.0, 0.0, 0.5, 1.0,
    -1.0,  1.0,  1.0,      1.0, 0.0, 0.5, 1.0,
    1.0,  1.0,  1.0,      1.0, 0.0, 0.5, 1.0,
    1.0,  1.0, -1.0,      1.0, 0.0, 0.5, 1.0,
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
  cube: Pipeline
  p1 = Transform()
  t1 = Transform(parent: addr p1)
  camera: Camera

proc load() =
  var ct = Transform(position: vec3(5, 0, 5))
  ct.lookAt(vec3(0, 0, 0), vec3(0, 1, 0))
  cube = pipeline(shader=graphics.shader(vertex, fragment), vertices=VERTICES, indices=INDICES)
  camera = graphics.perspective(ct, 60, 0.1, 100.0)
  graphics.color = vec4(0.0, 0.0, 0.0, 1.0)

proc draw() =
  let
    speed = 20.0
    r = runtime.age * runtime.delta * speed
  p1.position = vec3(2 * sin(runtime.age), 2 * cos(runtime.age), 0)
  t1.rotation = fromEuler(r, r, 0.0)
  cube.shader.set("MODEL", t1.world)
  graphics.render(cube, camera)

proc cleanup() = destroy(addr cube)

window(800, 600, "My Game", load, draw, cleanup)
