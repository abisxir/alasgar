import strutils
import strformat

import chroma
import ../ports/opengl

import ../utils
import ../shader
import ../texture
import ../mesh
import ../core
import depth_buffer

export opengl

type
    ShadowCaster* = object
        view: Mat4
        projection: Mat4
        mvp: Mat4
        map: DepthBuffer
    GraphicContext* = object
        environmentIntensity*: float32
        clearColor*: chroma.Color
        defaultShader*: Shader
        shaders*: seq[Shader]
        shadowCasters*: seq[ShadowCaster]

proc addShader*(g: var GraphicContext, shader: Shader) =
    if shader != nil and not g.shaders.contains(shader):
        add(g.shaders, shader)


