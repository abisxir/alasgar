import chroma

import ../ports/opengl
import ../utils
import ../shader
import ../texture

export opengl

type
    ShadowCaster* = object
        view*: Mat4
        projection*: Mat4
        position*: Vec3
        direct*: bool
        point*: bool
        size*: Vec2
        shadowMap*: Texture
        
    GraphicContext* = object
        environmentIntensity*: float32
        clearColor*: chroma.Color
        defaultShader*: Shader
        shaders*: seq[Shader]
        effects*: seq[Shader]
        shadowCasters*: seq[ShadowCaster]
        shaderParams*: seq[ShaderParam]

proc addShader*(g: var GraphicContext, shader: Shader) =
    if shader != nil and not contains(g.shaders, shader):
        add(g.shaders, shader)

