import types
import common
import skin


proc depthVertex*(POSITION: Layout[0, Vec3], 
                  NORMAL: Layout[1, Vec3],
                  UV: Layout[2, Vec4],
                  BONE: Layout[3, Vec4], 
                  WEIGHT: Layout[4, Vec4],
                  MODEL: Layout[5, Mat4],
                  MATERIAL_DATA: Layout[9, UVec4],
                  SPRITE: Layout[10, Vec4],
                  SKIN: Layout[11, Vec4],
                  SKIN_MAP: Layout[0, Uniform[Sampler2D]],
                  CAMERA: Uniform[Camera],
                  ENVIRONMENT: Uniform[Environment],
                  FRAME: Uniform[Frame],
                  SURFACE: var Surface,
                  MATERIAL: var Material,
                  SHADOW_MVP: Uniform[Mat4],
                  DEPTH: var float,
                  gl_Position: var Vec4) =
    
    let
        model = applySkinTransform(SKIN_MAP, ENVIRONMENT, MODEL, BONE, WEIGHT, SKIN)
        fragmentPosition = model * vec4(POSITION, 1)
        lightPosition = SHADOW_MVP * fragmentPosition
        nz = lightPosition.z / lightPosition.w
        
    DEPTH = 0.5 + (nz * 0.5)
    gl_Position = lightPosition

proc depthFragment*(DEPTH: var float) = discard
#proc depthFragment*(DEPTH: var float, COLOR) = discard
#    let 
#        dx: float = dFdx(DEPTH)   
#        dy: float = dFdy(DEPTH) 
#        y: float = DEPTH * DEPTH + 0.25 * (dx * dx + dy * dy)
#    # Compute second moment over the pixel extents.   
#    COLOR = vec2(DEPTH, y)

