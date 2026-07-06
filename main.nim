import math

import alasgar

var
  cubes: Pipeline
  t = Transform()
  camera: Camera

proc load() =
  let
    shape1 = graphics.cube(transform=translate(vec3(-2, 0, 0)), color=vec4(1, 0, 0, 1))
    shape2 = graphics.cube(transform=translate(vec3( 2, 0, 0)), color=vec4(0, 1, 0, 1))
  cubes = graphics.compact(shape1 + shape2)
  camera = graphics.perspective(vec3(5, 5, 5), vec3(0, 0, 0), 60, 0.1, 100.0)
  graphics.color = vec4(0.0, 0.0, 0.0, 1.0)

proc draw() =
  let
    speed = 20.0
    r = runtime.age * runtime.delta * speed
  t.rotation = fromEuler(r, r, 0.0)
  cubes.shader.set("MODEL", t.world)
  graphics.render(cubes, camera)
  graphics.debug()

proc cleanup() =
  destroy(cubes)

window(800, 600, "My Game", load, draw, cleanup)
