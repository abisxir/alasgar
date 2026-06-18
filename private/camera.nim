import aljebra
import core

type
  ProjectionType* = enum
    ptPerspective,
    ptOrtho
  CameraGLSL* = object
    VIEW*: Mat4
    PROJECTION* : Mat4
    VIEW_PROJECTION*: Mat4
    INV_VIEW*: Mat4
    INV_PROJECTION*: Mat4
    INV_VIEW_PROJECTION*: Mat4
    POSITION*: Vec3
    NEAR_PLANE*: float
    DIRECTION*: Vec3
    FAR_PLANE*: float
    ASPECT*: float
  Camera* = object
    case kind*: ProjectionType
      of ptPerspective:
        fovY*: float32
      of ptOrtho:
        height*: float32
    transform*: Transform
    aspect: float32
    nearZ*: float32
    farZ*: float32
    projection: Mat4
    direction*: Vec3
    up*: Vec3

var
  GLSL_CAMERA*: CameraGLSL

proc perspective*(g: ptr Graphics, transform: Transform, fovY, nearZ, farZ: float32): Camera =
  let aspect = g.aspect()
  Camera(
    kind: ptPerspective,
    transform: transform,
    aspect: aspect,
    nearZ: nearZ,
    farZ: farZ,
    projection: perspective(fovY, aspect, nearZ, farZ)
  )

func ortho*(g: ptr Graphics, transform: Transform, height, nearZ, farZ: float32): Camera =
  let
    w = height * g.aspect
  Camera(
    kind: ptOrtho,
    transform: transform,
    aspect: g.aspect,
    nearZ: nearZ,
    farZ: farZ,
    projection: ortho(-0.5 * w, 0.5 * w, -0.5 * height, -0.5 * height, nearZ, farZ)
  )
func `projection`*(c: Camera): Mat4 = c.projection
