## Alasgar engine public API.
##
## Import this module from applications and examples to access the engine's
## public types and helpers from one place:
##
## ```nim
## import alasgar
## ```
##
## The module re-exports the main engine API:
##
## - `core`: window, graphics, runtime, and engine state.
## - `aljebra`: vectors, matrices, quaternions, and math helpers.
## - `transform`: position, rotation, scale, and matrix conversion.
## - `camera`: perspective and orthographic camera construction.
## - `shader` and `glsl`: shader creation, uniforms, and Nim-to-GLSL helpers.
## - `pipeline`: vertex/index buffer setup and rendering.
##
## Basic use:
##
## ```nim
## import alasgar
##
## proc load() = discard
## proc draw() = discard
## proc cleanup() = discard
## window(800, 600, "My Game", load, draw, cleanup)
## ```
##
## Math types are available directly after importing `alasgar`:
##
## ```nim
## let position = vec3(1, 2, 3)
## let color = vec4(1, 0, 0, 1)
## ```
import private/core
import private/shader
import private/aljebra
import private/transform
import private/pipeline
import private/camera
import private/geometry
import private/debug
import private/utils
import private/texture
import private/text

export core, shader, glsl, aljebra, transform, pipeline, camera, geometry, debug, utils, texture, text
