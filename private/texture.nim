## Texture, sampler, and framebuffer view helpers.
##
## This module wraps the small set of objects needed for render targets
## and sampled textures:
##
## - `texture` creates a 2D texture with a color or depth format.
## - `sampler` creates texture filtering and wrapping state.
## - `view` creates a framebuffer backed by a texture.
## - `use` binds a framebuffer view for rendering.
## - `screen` restores rendering to the default framebuffer.

import ports/opengl
import core

type
  PixelAttachment* = enum
    ## Kind of data stored by a texture or framebuffer attachment.
    paColor
    paDepth
  Pixel = object
    attachment: PixelAttachment
    bits: int
    channels: int
  Texture* = object
    ## Texture handle and metadata.
    ##
    ## Textures are created with `texture` and must be released with
    ## `destroy` when they are no longer needed. If a texture is passed to
    ## `view`, destroy the resulting view instead; `destroy(view)` also deletes
    ## the backing texture.
    id: GLuint
    target: GLenum
    width: uint32
    height: uint32
    pixel: Pixel
    slices: int
    mipmaps: int
  TextureFilter* = enum
    ## Sampling filter used when a texel is magnified or minified.
    tfNearest
    tfLinear
  MipmapFilter* = enum
    ## Mipmap sampling mode for minification.
    mfNone
    mfNearest
    mfLinear
  TextureWrap* = enum
    ## Addressing mode used when texture coordinates fall outside 0..1.
    twRepeat
    twMirroredRepeat
    twClampToEdge
    twClampToBorder
  Sampler* = object
    ## Sampler object paired with a texture.
    ##
    ## Use `use(sampler, slot)` to bind both the texture and its sampler
    ## state to a texture unit.
    id: GLuint
    texture: Texture
    minFilter: TextureFilter
    magFilter: TextureFilter
    mipmapFilter: MipmapFilter
    wrapS: TextureWrap
    wrapT: TextureWrap
    wrapR: TextureWrap
  View* = object
    ## Framebuffer view backed by a texture.
    ##
    ## Views are created with `view` or `depth`, made active with `use`, and
    ## released with `destroy`. Destroying a view also destroys its backing
    ## texture.
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
  ## Create a texture object.
  ##
  ## `attachment` selects whether the texture stores color or depth data.
  ## `channels` and `bits` determine the external and internal pixel formats.
  ## `slices` selects the texture target: `1` creates a 2D texture, `6` creates
  ## a cube map target, and any other value creates a 2D array target.
  ##
  ## If `pixels` is non-nil, the pointer is uploaded as the level-0 image. When
  ## `mipmaps` is greater than 1, mipmaps are generated only for textures that
  ## were initialized with pixel data.
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

proc use*(texture: Texture, slot: int) =
  ## Bind `texture` to texture unit `slot`.
  glActiveTexture((GL_TEXTURE0.int + slot).GLenum)
  glBindTexture(texture.target, texture.id)

proc dismiss*(texture: Texture) =
  ## Unbind the current texture from `texture`'s target.
  glBindTexture(texture.target, 0)

proc `texture`*(view: View): Texture =
  ## Return the texture attached to this view.
  view.texture

proc destroy*(texture: var Texture) =
  ## Delete the texture object.
  ##
  ## The texture id is reset to 0, so calling this repeatedly is safe.
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
  ## Create a sampler object for `texture`.
  ##
  ## `minFilter`, `magFilter`, and `mipmapFilter` control sampling quality.
  ## `wrapS`, `wrapT`, and `wrapR` control addressing along each texture axis.
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

proc use*(sampler: Sampler, slot: int) =
  ## Bind the sampler's texture and sampler state to texture unit `slot`.
  use(sampler.texture, slot)
  glBindSampler(slot.GLuint, sampler.id)

proc destroy*(sampler: var Sampler) =
  ## Delete the sampler object.
  ##
  ## The sampler id is reset to 0, so calling this repeatedly is safe.
  if sampler.id != 0:
    glDeleteSamplers(1, sampler.id.addr)
    sampler.id = 0

proc view*(g: ptr Graphics, texture: Texture, slot: int = 0): View =
  ## Create a framebuffer view backed by `texture`.
  ##
  ## The returned view is responsible for deleting the framebuffer and the
  ## backing texture from `destroy(view)`.
  ##
  ## Color textures are attached to `GL_COLOR_ATTACHMENT0 + slot`. Depth
  ## textures are attached to `GL_DEPTH_ATTACHMENT` and disable color reads and
  ## writes for the framebuffer.
  ##
  ## Raises `ValueError` when OpenGL reports an incomplete framebuffer.
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
  case result.texture.pixel.attachment
  of paDepth:
    var none = GL_NONE.GLenum
    glDrawBuffers(1.GLsizei, none.addr)
    glReadBuffer(GL_NONE.GLenum)
  of paColor:
    var color = result.texture.attachmentPoint(slot)
    glDrawBuffers(1.GLsizei, color.addr)
    glReadBuffer(color)
  let status = glCheckFramebufferStatus(GL_FRAMEBUFFER)
  glBindFramebuffer(GL_FRAMEBUFFER, 0)
  if status != GL_FRAMEBUFFER_COMPLETE:
    raise newException(ValueError, "Framebuffer is incomplete")

proc view*(g: ptr Graphics, width, height: uint32): View =
  ## Create a color framebuffer view with the requested size.
  g.view(g.texture(width, height))

proc view*(g: ptr Graphics): View =
  ## Create a color framebuffer view matching the current render screen size.
  g.view(g.size.x, g.size.y)

proc depth*(g: ptr Graphics, width, height: uint32): View =
  ## Create a depth framebuffer view with the requested size.
  g.view(g.texture(width, height, attachment=paDepth, bits=16))

proc depth*(g: ptr Graphics): View =
  ## Create a depth framebuffer view matching the current render screen size.
  g.depth(g.size.x, g.size.y)

func `clearBit`(view: View): GLbitfield =
  case view.texture.pixel.attachment
  of paDepth: GL_DEPTH_BUFFER_BIT
  of paColor: GL_COLOR_BUFFER_BIT

proc use*(view: View) =
  ## Bind `view` as the active framebuffer, set its viewport, and clear it.
  ##
  ## Depth testing is enabled before clearing. Color views clear the color
  ## buffer; depth views clear the depth buffer.
  glBindFramebuffer(GL_FRAMEBUFFER, view.id)
  glViewport(0, 0, view.texture.width.GLsizei, view.texture.height.GLsizei)
  glEnable(GL_DEPTH_TEST)
  glClear(view.clearBit)

proc screen*(g: ptr Graphics) =
  ## Restore rendering to the default framebuffer.
  ##
  ## The viewport is reset to the current render screen size.
  let size = g.size
  var back = GL_BACK
  glBindFramebuffer(GL_FRAMEBUFFER, 0)
  glDrawBuffers(1.GLsizei, back.addr)
  glReadBuffer(GL_BACK)
  glViewport(0, 0, size.x.GLsizei, size.y.GLsizei)

proc destroy*(view: var View) =
  ## Delete the framebuffer and its backing texture.
  ##
  ## The framebuffer id is reset to 0, so calling this repeatedly is safe.
  if view.id > 0:
    glDeleteFramebuffers(1, addr view.id)
    view.id = 0
    destroy(view.texture)
