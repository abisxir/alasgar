import std/math

import alasgar

proc vs(
  IN_POSITION: Layout[0, Vec3],
  IN_COLOR: Layout[3, Vec4],
  MODEL: Uniform[Mat4],
  TINT: Uniform[Vec4],
  VS_COLOR: var Vec4,
) =
  gl_Position = GLSL_CAMERA.PROJECTION * GLSL_CAMERA.VIEW * MODEL * vec4(IN_POSITION, 1)
  VS_COLOR = IN_COLOR * TINT

proc fs(
  VS_COLOR: Vec4,
  OUT_COLOR: var Layout[0, Vec4],
) =
  OUT_COLOR = VS_COLOR

type
  ShapeItem = object
    mesh: Mesh
    transform: Transform
    color: Vec4
    spin: Vec3

var
  shapes: array[5, ShapeItem]
  camera: Camera

proc newShape(geometry: Geometry, position, color, spin: Vec3): ShapeItem =
  result.mesh = graphics.compact(graphics.shader(vs, fs), geometry)
  result.transform = Transform(position: position)
  result.color = vec4(color, 1)
  result.spin = spin

proc load() =
  var cameraTransform = Transform(position: vec3(0.0, 3.5, 8.0))
  cameraTransform.lookAt(vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0))

  camera = graphics.perspective(cameraTransform, 60, 0.1, 100)
  graphics.color = vec4(0.08, 0.09, 0.12, 1)

  shapes[0] = newShape(graphics.cube(), vec3(-3.2, 0.0, 0.0), vec3(1.0, 0.35, 0.25), vec3(0.8, 1.2, 0.2))
  shapes[1] = newShape(graphics.sphere(), vec3(-1.6, 0.0, 0.0), vec3(0.25, 0.65, 1.0), vec3(0.2, 1.0, 0.8))
  shapes[2] = newShape(graphics.cylinder(), vec3(0.0, 0.0, 0.0), vec3(0.35, 1.0, 0.5), vec3(1.0, 0.3, 0.7))
  shapes[3] = newShape(graphics.torus(), vec3(1.6, 0.0, 0.0), vec3(1.0, 0.8, 0.25), vec3(0.7, 1.1, 0.4))
  shapes[4] = newShape(graphics.plane(), vec3(3.2, 0.0, 0.0), vec3(0.85, 0.45, 1.0), vec3(1.1, 0.4, 0.9))

proc draw() =
  for item in shapes.mitems:
    let spin = item.spin * runtime.age
    item.transform.rotation = fromEuler(spin.x, spin.y, spin.z)
    item.mesh.shader.set("MODEL", item.transform.world)
    item.mesh.shader.set("TINT", item.color)
    graphics.render(item.mesh, camera)

proc cleanup() =
  for item in shapes.mitems:
    destroy(item.mesh)

window(960, 540, "Hello Shapes", load, draw, cleanup)
