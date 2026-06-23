import ports/opengl

type
  Pixel* = object
    channels*: int
    bits*: int
  Texture* = object
    id: GLuint
    target: GLenum
    width: int
    height: int
    pixel: Pixel
    slices: int
    mipmaps: int
  TextureFilter* = enum
    tfNearest
    tfLinear
  MipmapFilter* = enum
    mfNone
    mfNearest
    mfLinear
  TextureWrap* = enum
    twRepeat
    twMirroredRepeat
    twClampToEdge
    twClampToBorder
  Sampler* = object
    id: GLuint
    texture: Texture
    minFilter: TextureFilter
    magFilter: TextureFilter
    mipmapFilter: MipmapFilter
    wrapS: TextureWrap
    wrapT: TextureWrap
    wrapR: TextureWrap

func `format`(p: Pixel): GLenum =
  case p.channels
  of 1: GL_RED
  of 2: GL_RG
  of 3: GL_RGB
  else: GL_RGBA

func `size`(p: Pixel): GLenum =
  case p.bits
  of 16:
    when declared(GL_R16):
      case p.channels
      of 1: GL_R16
      of 2: GL_RG16
      of 3: GL_RGB16
      else: GL_RGBA16
    else:
      case p.channels
      of 1: GL_R16F
      of 2: GL_RG16F
      of 3: GL_RGB16F
      else: GL_RGBA16F
  of 32:
    case p.channels
    of 1: GL_R32F
    of 2: GL_RG32F
    of 3: GL_RGB32F
    else: GL_RGBA32F
  else:
    case p.channels
    of 1: GL_R8
    of 2: GL_RG8
    of 3: GL_RGB8
    else: GL_RGBA8

proc `dataType`(p: Pixel): GLenum =
  case p.bits
  of 16:
    when declared(GL_R16):
      GL_UNSIGNED_SHORT
    else:
      GL_HALF_FLOAT
  of 32: cGL_FLOAT
  else: GL_UNSIGNED_BYTE

func `gl`(filter: TextureFilter): GLenum =
  case filter
  of tfNearest: GL_NEAREST
  of tfLinear: GL_LINEAR

func minFilterGl(filter: TextureFilter, mipmapFilter: MipmapFilter): GLenum =
  case mipmapFilter
  of mfNone:
    filter.gl
  of mfNearest:
    case filter
    of tfNearest: GL_NEAREST_MIPMAP_NEAREST
    of tfLinear: GL_LINEAR_MIPMAP_NEAREST
  of mfLinear:
    case filter
    of tfNearest: GL_NEAREST_MIPMAP_LINEAR
    of tfLinear: GL_LINEAR_MIPMAP_LINEAR

func `gl`(wrap: TextureWrap): GLenum =
  case wrap
  of twRepeat: GL_REPEAT
  of twMirroredRepeat: GL_MIRRORED_REPEAT
  of twClampToEdge: GL_CLAMP_TO_EDGE
  of twClampToBorder:
    when declared(GL_CLAMP_TO_BORDER):
      GL_CLAMP_TO_BORDER
    else:
      GL_CLAMP_TO_EDGE

func `target`(slices: int): GLenum =
  case slices
  of 1: GL_TEXTURE_2D
  of 6: GL_TEXTURE_CUBE_MAP
  else: GL_TEXTURE_2D_ARRAY

proc texture*(
  width, height: int,
  channels: int = 4,
  bits: int = 8,
  slices: int = 1,
  mipmaps: int = 1,
  pixels: pointer = nil,
): Texture =
  let
    pixel = Pixel(bits: bits, channels: channels)
    target = slices.target
    format = pixel.format
    internalFormat = pixel.size
    dataType = pixel.dataType

  result = Texture(
    target: target,
    width: width,
    height: height,
    pixel: pixel,
    slices: slices,
    mipmaps: mipmaps,
  )

  glGenTextures(1, result.id.addr)
  glBindTexture(result.target, result.id)
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
  glTexImage2D(
    result.target,
    0.GLint,
    internalFormat.GLint,
    result.width.GLsizei,
    result.height.GLsizei,
    0.GLint,
    format,
    dataType,
    pixels,
  )
  if mipmaps > 1 and not isNil(pixels):
    glGenerateMipmap(result.target)
  glBindTexture(result.target, 0)

proc attach*(texture: Texture, slot: int) =
  glActiveTexture((GL_TEXTURE0.int + slot).GLenum)
  glBindTexture(texture.target, texture.id)

proc destroy*(texture: var Texture) =
  if texture.id != 0:
    glDeleteTextures(1, texture.id.addr)
    texture.id = 0

proc sampler*(
  texture: Texture,
  minFilter: TextureFilter = tfLinear,
  magFilter: TextureFilter = tfLinear,
  mipmapFilter: MipmapFilter = mfNone,
  wrapS: TextureWrap = twClampToEdge,
  wrapT: TextureWrap = twClampToEdge,
  wrapR: TextureWrap = twClampToEdge,
): Sampler =
  result = Sampler(
    texture: texture,
    minFilter: minFilter,
    magFilter: magFilter,
    mipmapFilter: mipmapFilter,
    wrapS: wrapS,
    wrapT: wrapT,
    wrapR: wrapR,
  )

  glGenSamplers(1, addr result.id)
  glSamplerParameteri(
    result.id,
    GL_TEXTURE_MIN_FILTER,
    minFilterGl(result.minFilter, result.mipmapFilter).GLint,
  )
  glSamplerParameteri(result.id, GL_TEXTURE_MAG_FILTER, result.magFilter.gl.GLint)
  glSamplerParameteri(result.id, GL_TEXTURE_WRAP_S, result.wrapS.gl.GLint)
  glSamplerParameteri(result.id, GL_TEXTURE_WRAP_T, result.wrapT.gl.GLint)
  glSamplerParameteri(result.id, GL_TEXTURE_WRAP_R, result.wrapR.gl.GLint)

proc attach*(sampler: Sampler, slot: int) =
  attach(sampler.texture, slot)
  glBindSampler(slot.GLuint, sampler.id)
