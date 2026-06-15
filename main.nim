import math

import alasgar
import private/ports/opengl
import private/aljebra

proc vertex(
  IN_POSITION: Layout[0, Vec3],
  IN_COLOR: Layout[1, Vec4],
  PROJECTION: Uniform[Mat4],
  VIEW: Uniform[Mat4],
  MODEL: Uniform[Mat4],
  COLOR: var Vec4,
  gl_Position: var Vec4
) =
  gl_Position = PROJECTION * VIEW * MODEL * vec4(IN_POSITION, 1)
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
  p1: Pipeline
  model: Mat4
  projection: Mat4
  view: Mat4

proc load() =
  p1 = pipeline(shader=shader(vertex, fragment), vertices=VERTICES, indices=INDICES)
  model = mat4()
  projection = perspective(60, 800.0 / 600.0, 0.1, 100.0)

proc draw() =
  graphics.color = vec4(0.0, 0.0, 0.0, 1.0)
  view = lookAt(vec3(5.0, 0.0, 5.0), vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0))
  p1.shader.set("PROJECTION", projection)
  p1.shader.set("VIEW", view)
  p1.shader.set("MODEL", model)
  graphics.render(p1)

proc cleanup() = destroy(addr p1)

window(800, 600, "My Game", load, draw, cleanup)
