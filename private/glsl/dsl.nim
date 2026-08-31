## Shader DSL type wrappers.
##
## These types exist to let shader procs declare params like
## `P: Layout[0, Vec3]`, `T: Uniform[Mat4]` or batches
## `O: Batch[2, Vec3]`. Their GLSL meaning is extracted by the compiler at
## macro time (`layout(location=0) in vec3 P;` and so on).

import ../aljebra

type
  Layout*[N, T] = T
  Batch*[N, T] = T
  Uniform*[T] = T
  UniformWriteOnly*[T] = T
  Attribute*[T] = T
  SamplerBuffer* = object
  Sampler1D* = object
  Sampler1DArray* = object
  Sampler2D* = object
  Sampler2DArray* = object
  Sampler2DRect* = object
  Sampler3D* = object
  SamplerCube* = object
  SamplerCubeArray* = object
  Sampler1DShadow* = object
  Sampler1DArrayShadow* = object
  Sampler2DShadow* = object
  Sampler2DArrayShadow* = object
  Sampler2DRectShadow* = object
  SamplerCubeShadow* = object
  SamplerCubeArrayShadow* = object
  ImageBuffer* = object
  ISamplerBuffer* = object
  ISampler1D* = object
  ISampler1DArray* = object
  ISampler2D* = object
  ISampler2DArray* = object
  ISampler2DRect* = object
  ISampler3D* = object
  ISamplerCube* = object
  ISamplerCubeArray* = object
  ISampler1DShadow* = object
  ISampler1DArrayShadow* = object
  ISampler2DShadow* = object
  ISampler2DArrayShadow* = object
  ISampler2DRectShadow* = object
  ISamplerCubeShadow* = object
  ISamplerCubeArrayShadow* = object
  IImageBuffer* = object
  USamplerBuffer* = object
  USampler1D* = object
  USampler1DArray* = object
  USampler2D* = object
  USampler2DArray* = object
  USampler2DRect* = object
  USampler3D* = object
  USamplerCube* = object
  USamplerCubeArray* = object
  USampler1DShadow* = object
  USampler1DArrayShadow* = object
  USampler2DShadow* = object
  USampler2DArrayShadow* = object
  USampler2DRectShadow* = object
  USamplerCubeShadow* = object
  USamplerCubeArrayShadow* = object
  UImageBuffer* = object

proc texelFetch*(sampler: Sampler2D, P: IVec2, lod: int): Vec4 = discard
proc textureLod*(sampler: SamplerCube, P: Vec3, lod: float): Vec4 = discard
proc texture*(sampler: Sampler2D, P: Vec2): Vec4 = discard
proc texture*(sampler: Sampler2DShadow, P: Vec3): float = discard
proc texture*(sampler: Sampler2DArray, P: Vec3): Vec4 = discard
proc texture*(sampler: Sampler2DArrayShadow, P: Vec4): float = discard
proc textureSize*(sampler: Sampler1D, lod: int): int = discard
proc textureSize*(sampler: Sampler2D, lod: int): IVec2 = discard
proc textureSize*(sampler: Sampler3D, lod: int): IVec3 = discard
proc textureSize*(sampler: Sampler1D): int = discard
proc textureSize*(sampler: Sampler2D): IVec2 = discard
proc textureSize*(sampler: Sampler3D): IVec3 = discard

var
  gl_Position*: Vec4
