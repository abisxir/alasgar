import math

import alasgar

var
  logo: Pipeline
  t = Transform(scale:vec3(0.1))
  camera: Camera

proc load() =
  logo = graphics.compact(graphics.text.shape("It is a [red]text [white]shape!", transform=translate(vec3(-60, -10, 0))))
  camera = graphics.perspective(vec3(5, 5, 5), vec3(0, 0, 0), 60, 0.1, 100.0)
  graphics.color = vec4(0.0, 0.0, 0.0, 1.0)

proc draw() =
  let
    speed = 20.0
    r = runtime.age * runtime.delta * speed
  t.rotation = fromEuler(r, r, 0.0)
  logo.shader.set("MODEL", t.world)
  graphics.render(logo, camera)
  graphics.text.draw("ALASGAR is running [green]:)", vec2(8, 8))

proc cleanup() =
  destroy(logo)

window(800, 600, "My Game", load, draw, cleanup)
