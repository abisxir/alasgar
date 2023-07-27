import types

proc effectVertex*(CAMERA: Uniform[Camera],
                   FRAME: Uniform[Frame],
                   gl_VertexID: int,
                   UV: var Vec2,
                   gl_Position: var Vec4) =
    let v1: int = gl_VertexID and 1
    let v2: int = gl_VertexID and 2
    let x: float = float(v1 shl 2)
    let y: float = float(v2 shl 1)
    UV.x = x * 0.5
    UV.y = y * 0.5
    gl_Position = vec4(x - 1.0, y - 1.0, 0.0, 1.0)
    
proc effectFragment*(CAMERA: Uniform[Camera],
                     FRAME: Uniform[Frame],
                     COLOR_CHANNEL: Layout[0, Uniform[Sampler2D]],
                     NORMAL_CHANNEL: Layout[1, Uniform[Sampler2D]],
                     DEPTH_CHANNEL: Layout[2, Uniform[Sampler2D]],
                     UV: Vec2,
                     COLOR: var Vec4) =
    COLOR = texture(COLOR_CHANNEL, UV)