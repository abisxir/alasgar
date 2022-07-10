import strutils
import strformat

import chroma
import ../ports/opengl

import ../utils
import ../shader
import ../texture
import ../mesh
import ../core

export opengl

type
    ShadowCaster* = object
        view*: Mat4
        projection*: Mat4
        position*: Vec3
        direct*: bool
        point*: bool
        size*: Vec2
    GraphicContext* = object
        maxBatchSize*: int
        environmentIntensity*: float32
        clearColor*: chroma.Color
        defaultShader*: Shader
        shaders*: seq[Shader]
        shadowCasters*: seq[ShadowCaster]
        shaderParams*: seq[ShaderParam]
        fxaaEnabled*: bool
        fxaaSpanMax*: float
        fxaaReduceMul*: float
        fxaaReduceMin*: float

proc addShader*(g: var GraphicContext, shader: Shader) =
    if shader != nil and not contains(g.shaders, shader):
        add(g.shaders, shader)


