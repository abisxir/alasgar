import ports/opengl
import core

type
  PixelAttachment* = enum
    paColor
    paDepth
  Pixel = object
    attachment: PixelAttachment
    bits: int
    channels: int
  Texture* = object
    id: GLuint
    target: GLenum
    width: uint32
    height: uint32
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
  View* = object
    id: GLuint
    texture: Texture


func externalFormat(p: Pixel): GLenum =
  case p.attachment
  of paColor:
    case p.channels
    of 1: GL_RED
    of 2: GL_RG
    of 3: GL_RGB
    else: GL_RGBA
  of paDepth:
    GL_DEPTH_COMPONENT


func internalFormat(p: Pixel): GLenum =
  case p.attachment:
  of paColor:
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
  of paDepth:
    case p.bits
    of 16: GL_DEPTH_COMPONENT16
    of 32: GL_DEPTH_COMPONENT32F
    else: GL_DEPTH_COMPONENT24

proc `dataType`(p: Pixel): GLenum =
  case p.attachment
  of paColor:
    case p.bits
    of 16:
      when declared(GL_R16):
        GL_UNSIGNED_SHORT
      else:
        GL_HALF_FLOAT
    of 32: cGL_FLOAT
    else: GL_UNSIGNED_BYTE
  of paDepth:
    case p.bits
    of 16: GL_UNSIGNED_SHORT
    of 24: GL_UNSIGNED_INT
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

func attachmentPoint(texture: Texture, slot: int): GLenum =
  case texture.pixel.attachment
  of paColor:
    (GL_COLOR_ATTACHMENT0.int + slot).GLenum
  of paDepth:
    GL_DEPTH_ATTACHMENT

func defaultFilter(texture: Texture): GLenum =
  case texture.pixel.attachment
  of paColor: GL_LINEAR
  of paDepth: GL_NEAREST

proc texture*(
  g: ptr Graphics,
  width, height: uint32,
  attachment: PixelAttachment = paColor,
  channels: int = 4,
  bits: int = 8,
  slices: int = 1,
  mipmaps: int = 1,
  pixels: pointer = nil,
): Texture =
  discard g
  let
    pixel = Pixel(attachment: attachment, bits: bits, channels: channels)
    target = slices.target

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
  glTexParameteri(result.target, GL_TEXTURE_MIN_FILTER, result.defaultFilter.GLint)
  glTexParameteri(result.target, GL_TEXTURE_MAG_FILTER, result.defaultFilter.GLint)
  glTexParameteri(result.target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE.GLint)
  glTexParameteri(result.target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE.GLint)
  glTexImage2D(
    result.target,
    0.GLint,
    pixel.internalFormat.GLint,
    result.width.GLsizei,
    result.height.GLsizei,
    0.GLint,
    pixel.externalFormat,
    pixel.dataType,
    pixels,
  )
  if mipmaps > 1 and not isNil(pixels):
    glGenerateMipmap(result.target)
  glBindTexture(result.target, 0)

proc attach*(texture: Texture, slot: int) =
  glActiveTexture((GL_TEXTURE0.int + slot).GLenum)
  glBindTexture(texture.target, texture.id)

proc dismiss*(texture: Texture) =
  glBindTexture(texture.target, 0)

proc `texture`*(view: View): Texture =
  ## Return the texture attached to this view.
  view.texture

proc destroy*(texture: var Texture) =
  if texture.id != 0:
    glDeleteTextures(1, texture.id.addr)
    texture.id = 0

proc sampler*(
  g: ptr Graphics,
  texture: Texture,
  minFilter: TextureFilter = tfLinear,
  magFilter: TextureFilter = tfLinear,
  mipmapFilter: MipmapFilter = mfNone,
  wrapS: TextureWrap = twClampToEdge,
  wrapT: TextureWrap = twClampToEdge,
  wrapR: TextureWrap = twClampToEdge,
): Sampler =
  discard g
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

proc destroy*(sampler: var Sampler) =
  if sampler.id != 0:
    glDeleteSamplers(1, sampler.id.addr)
    sampler.id = 0

proc view*(g: ptr Graphics, texture: Texture, slot: int = 0): View =
  discard g
  result.texture = texture
  glGenFramebuffers(1, addr result.id)
  glBindFramebuffer(GL_FRAMEBUFFER, result.id)
  glFramebufferTexture2D(
      GL_FRAMEBUFFER,
      result.texture.attachmentPoint(slot),
      result.texture.target,
      result.texture.id,
      0
  )
  if result.texture.pixel.attachment == paDepth:
    var none = GL_NONE.GLenum
    glDrawBuffers(1.GLsizei, none.addr)
    glReadBuffer(GL_NONE.GLenum)
  if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
    raise newException(ValueError, "Framebuffer is incomplete")

proc view*(g: ptr Graphics, width, height: uint32): View = g.view(g.texture(width, height))
proc view*(g: ptr Graphics): View = g.view(g.size.x, g.size.y)

proc depth*(g: ptr Graphics, width, height: uint32): View = g.view(g.texture(width, height, attachment=paDepth, bits=16))
proc depth*(g: ptr Graphics): View = g.depth(g.size.x, g.size.y)

func `clearBit`(view: View): GLbitfield =
  case view.texture.pixel.attachment
  of paDepth: GL_DEPTH_BUFFER_BIT
  of paColor: GL_COLOR_BUFFER_BIT

proc use*(view: View) =
  glBindFramebuffer(GL_FRAMEBUFFER, view.id)
  glViewport(0, 0, view.texture.width.GLsizei, view.texture.height.GLsizei)
  glClear(view.clearBit)

proc screen*(g: ptr Graphics) =
  let size = g.size
  var back = GL_BACK.GLenum
  glBindFramebuffer(GL_FRAMEBUFFER, 0)
  glDrawBuffers(1.GLsizei, back.addr)
  glReadBuffer(GL_BACK.GLenum)
  glViewport(0, 0, size.x.GLsizei, size.y.GLsizei)

proc destroy*(view: var View) =
  if view.id > 0:
    glDeleteFramebuffers(1, addr view.id)
    view.id = 0
    destroy(view.texture)
