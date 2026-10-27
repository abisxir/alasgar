## Single source of truth for GLSL built-in names.
##
## Everything that GLSL (and the GLSL ES / desktop dialects used by this
## engine) provides natively lives here. The compiler never guesses: a name
## that is not mentioned in this module and not resolved to a scoped
## definition is a compile-time error, never a silent passthrough.

type
  ElementKind* = enum
    ekFloat, ekInt, ekUint

const
  ## Scalar type renames (Nim name -> GLSL name).
  scalars*: seq[(string, string)] = @[
    ("float32", "float"), ("float64", "float"), ("float", "float"),
    ("int8", "int"), ("int16", "int"), ("int32", "int"),
    ("int64", "int"), ("int", "int"),
    ("uint8", "uint"), ("uint16", "uint"), ("uint32", "uint"),
    ("uint64", "uint"), ("uint", "uint"),
    ("bool", "bool"),
  ]

  ## Alias renames for common vector/matrix/type names.
  aliases*: seq[(string, string)] = @[
    ("Vec2", "vec2"), ("Vec3", "vec3"), ("Vec4", "vec4"),
    ("IVec2", "ivec2"), ("IVec3", "ivec3"), ("IVec4", "ivec4"),
    ("UVec2", "uvec2"), ("UVec3", "uvec3"), ("UVec4", "uvec4"),
    ("DVec2", "dvec2"), ("DVec3", "dvec3"), ("DVec4", "dvec4"),
    ("Mat2", "mat2"), ("Mat3", "mat3"), ("Mat4", "mat4"),
    ("DMat2", "dmat2"), ("DMat3", "dmat3"), ("DMat4", "dmat4"),
    ("Quat", "vec4"),
  ]

  ## Generic vector types: name, GLSL base for float, dim, element kind.
  genVecTypes*: seq[(string, string, int, ElementKind)] = @[
    ("GVec2", "vec2", 2, ekFloat),
    ("GVec3", "vec3", 3, ekFloat),
    ("GVec4", "vec4", 4, ekFloat),
    ("GQuat", "vec4", 4, ekFloat),
  ]

  ## Generic matrix types: GMatN -> matN.
  genMatTypes*: seq[(string, string, int)] = @[
    ("GMat2", "mat2", 2),
    ("GMat3", "mat3", 3),
    ("GMat4", "mat4", 4),
  ]

  ## Sampler types (Nim name -> GLSL name).
  samplers*: seq[(string, string)] = @[
    ("SamplerBuffer", "samplerBuffer"),
    ("Sampler1D", "sampler1D"),
    ("Sampler1DArray", "sampler1DArray"),
    ("Sampler2D", "sampler2D"),
    ("Sampler2DArray", "sampler2DArray"),
    ("Sampler2DRect", "sampler2DRect"),
    ("Sampler3D", "sampler3D"),
    ("SamplerCube", "samplerCube"),
    ("SamplerCubeArray", "samplerCubeArray"),
    ("Sampler1DShadow", "sampler1DShadow"),
    ("Sampler1DArrayShadow", "sampler1DArrayShadow"),
    ("Sampler2DShadow", "sampler2DShadow"),
    ("Sampler2DArrayShadow", "sampler2DArrayShadow"),
    ("Sampler2DRectShadow", "sampler2DRectShadow"),
    ("SamplerCubeShadow", "samplerCubeShadow"),
    ("SamplerCubeArrayShadow", "samplerCubeArrayShadow"),
    ("ImageBuffer", "imageBuffer"),
    ("IImageBuffer", "iimageBuffer"),
    ("ISamplerBuffer", "isamplerBuffer"),
    ("ISampler1D", "isampler1D"),
    ("ISampler1DArray", "isampler1DArray"),
    ("ISampler2D", "isampler2D"),
    ("ISampler2DArray", "isampler2DArray"),
    ("ISampler2DRect", "isampler2DRect"),
    ("ISampler3D", "isampler3D"),
    ("ISamplerCube", "isamplerCube"),
    ("ISamplerCubeArray", "isamplerCubeArray"),
    ("ISampler1DShadow", "isampler1DShadow"),
    ("ISampler1DArrayShadow", "isampler1DArrayShadow"),
    ("ISampler2DShadow", "isampler2DShadow"),
    ("ISampler2DArrayShadow", "isampler2DArrayShadow"),
    ("ISampler2DRectShadow", "isampler2DRectShadow"),
    ("ISamplerCubeShadow", "isamplerCubeShadow"),
    ("ISamplerCubeArrayShadow", "isamplerCubeArrayShadow"),
    ("UImageBuffer", "uimageBuffer"),
    ("USamplerBuffer", "usamplerBuffer"),
    ("USampler1D", "usampler1D"),
    ("USampler1DArray", "usampler1DArray"),
    ("USampler2D", "usampler2D"),
    ("USampler2DArray", "usampler2DArray"),
    ("USampler2DRect", "usampler2DRect"),
    ("USampler3D", "usampler3D"),
    ("USamplerCube", "usamplerCube"),
    ("USamplerCubeArray", "usamplerCubeArray"),
    ("USampler1DShadow", "usampler1DShadow"),
    ("USampler1DArrayShadow", "usampler1DArrayShadow"),
    ("USampler2DShadow", "usampler2DShadow"),
    ("USampler2DArrayShadow", "usampler2DArrayShadow"),
    ("USampler2DRectShadow", "usampler2DRectShadow"),
    ("USamplerCubeShadow", "usamplerCubeShadow"),
    ("USamplerCubeArrayShadow", "usamplerCubeArrayShadow"),
  ]

  ## GLSL globals that must not be re-declared in the shader source.
  glslGlobals* = [
    "gl_Position",
    "gl_FragCoord",
    "gl_GlobalInvocationID",
    "gl_LocalInvocationID",
    "gl_WorkGroupID",
    "gl_VertexID",
    "gl_InstanceID",
    "gl_FrontFacing",
    "gl_PointCoord",
    "gl_PointSize",
    "gl_DrawID",
    "gl_SampleID",
    "gl_NumSamples",
    "GLSL_CAMERA",
  ]

  ## GLSL built-in functions. Calls to these names pass through unchanged.
  glslFunctions*: seq[string] = @[
    # vector/matrix constructors
    "vec2", "vec3", "vec4", "ivec2", "ivec3", "ivec4",
    "uvec2", "uvec3", "uvec4", "dvec2", "dvec3", "dvec4",
    "mat2", "mat3", "mat4", "dmat2", "dmat3", "dmat4",
    # common
    "abs", "sign", "floor", "ceil", "round", "trunc", "fract",
    "mod", "min", "max", "clamp", "mix", "step", "smoothstep",
    "pow", "exp", "exp2", "log", "log2", "sqrt", "inversesqrt",
    "sin", "cos", "tan", "asin", "acos", "atan",
    "sinh", "cosh", "tanh", "asinh", "acosh", "atanh",
    "radians", "degrees", "frexp", "ldexp",
    # geometric
    "length", "distance", "dot", "cross", "normalize",
    "faceforward", "reflect", "refract",
    "transpose", "determinant", "inverse", "matrixCompMult", "outerProduct",
    # relational
    "lessThan", "lessThanEqual", "greaterThan", "greaterThanEqual",
    "equal", "notEqual", "any", "all", "not", "isnan", "isinf",
    "bitfieldExtract", "bitfieldInsert", "bitfieldReverse", "bitCount",
    "findLSB", "findMSB", "uaddCarry", "usubBorrow", "umulExtended",
    # textures / images
    "texture", "textureLod", "textureGrad", "texelFetch", "texelFetchOffset",
    "textureProj", "textureSize", "textureQueryLevels", "textureQueryLod",
    "textureOffset", "textureProjLod", "textureLodOffset", "textureGradOffset",
    "imageLoad", "imageStore", "imageSize", "imageAtomicAdd",
    # derivative (fragment)
    "dFdx", "dFdy", "fwidth",
    # pack/unpack
    "packUnorm4x8", "unpackUnorm4x8", "packUnorm2x16", "unpackUnorm2x16",
    "packHalf2x16", "unpackHalf2x16", "packSnorm4x8", "unpackSnorm4x8",
    "packSnorm2x16", "unpackSnorm2x16", "packDouble2x32",
    # conversions
    "uint", "int", "float", "bool",
  ]

  ## Vector swizzle families.
  swizzleFamilies* = ["xyzw", "rgba", "stpq"]

proc isSwizzle*(s: string): bool =
  if s.len == 0 or s.len > 4:
    return false
  for fam in swizzleFamilies:
    if s[0] in fam:
      for c in s:
        if c notin fam:
          return false
      return true
  false

proc lookup*(tab: openArray[(string, string)], name: string): string =
  for (k, v) in tab:
    if k == name:
      return v

proc samplerGlsl*(name: string): string =
  lookup(samplers, name)

proc isSamplerType*(name: string): bool =
  name.samplerGlsl.len > 0

proc isBuiltinFunc*(name: string): bool =
  for n in glslFunctions:
    if n == name:
      return true
  false

proc elementKindOf*(name: string): ElementKind =
  case name
  of "float32", "float64", "float": ekFloat
  of "int8", "int16", "int32", "int64", "int": ekInt
  of "uint8", "uint16", "uint32", "uint64", "uint": ekUint
  else: ekFloat
