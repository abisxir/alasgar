import chroma

import ../ports/opengl
import ../utils
import ../shaders/base
import ../texture

export opengl

type
    ShadowCaster* = object
        view*: Mat4
        projection*: Mat4
        position*: Vec3
        point*: bool
        size*: Vec2
        shadowMap*: Texture
        
    GraphicsContext* = object
        environmentIntensity*: float32
        environmentBlurrity*: float32
        clearColor*: chroma.Color
        defaultShader*: Shader
        shaders*: seq[Shader]
        effects*: seq[Shader]
        shadowCasters*: seq[ShadowCaster]
        #shaderParams*: seq[ShaderParam]

proc addShader*(g: var GraphicsContext, shader: Shader) =
    if shader != nil and not contains(g.shaders, shader):
        add(g.shaders, shader)


