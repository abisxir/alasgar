import math

import alasgar

var
  cube: Mesh
  t = Transform()
  camera: Camera

proc load() =
  cube = graphics.compact(graphics.cube())
  camera = graphics.perspective(vec3(5, 5, 5), vec3(0, 0, 0), 60, 0.1, 100.0)
  graphics.color = vec4(0.0, 0.0, 0.0, 1.0)

proc draw() =
  let
    speed = 20.0
    r = runtime.age * runtime.delta * speed
  t.rotation = fromEuler(r, r, 0.0)
  cube.shader.set("MODEL", t.world)
  graphics.render(cube, camera)

proc cleanup() =
  destroy(cube)

window(800, 600, "My Game", load, draw, cleanup)
