
import hashes
import tables
import strutils
import ports/opengl

import resources/image
import utils
import container

type
    Texture* = ref object
        buffer: GLuint
        width: int32
        height: int32
        ratio: Vec2
        levels: int32
        target: GLenum
        internalFormat: GLenum
        minFilter: GLenum
        uvChannel*: int

template `id`*(t: Texture): GLuint = t.buffer
template `levels`*(t: Texture): int32 = t.levels
template `width`*(t: Texture): int32 = t.width
template `height`*(t: Texture): int32 = t.height

proc destroyTexture(t: Texture) =
    if t != nil and t.buffer != 0:
        echo &"Destroying texture[{t.buffer}]..."
        glDeleteTextures(1, t.buffer.addr)
        t.buffer = 0 

proc hash*(t: Texture): Hash = 
    if t != nil:
        int(t.buffer)
    else:
        0

var cache = newCachedContainer[Texture](destroyTexture)

proc createTexture(target: GLenum,
                   width, 
                   height: int, 
                   wrapS=GL_CLAMP_TO_EDGE, 
                   wrapT=GL_CLAMP_TO_EDGE, 
                   wrapR=GL_CLAMP_TO_EDGE, 
                   minFilter=GL_NEAREST, 
                   magFilter=GL_NEAREST, 
                   levels=1,
                   internalFormat:GLenum=GL_RGBA8): Texture =
    new(result)
    result.width = width.int32
    result.height = height.int32
    result.ratio = vec2(1, height.float32 / width.float32)
    result.levels = levels.int32
    result.target = target
    result.internalFormat = internalFormat
    result.minFilter = minFilter

    glGenTextures(1, result.buffer.addr)
    glBindTexture(target, result.buffer)
    glTexParameteri(target, GL_TEXTURE_WRAP_S, wrapS.GLint)
    glTexParameteri(target, GL_TEXTURE_WRAP_T, wrapT.GLint)
    glTexParameteri(target, GL_TEXTURE_WRAP_R, wrapR.GLint)
    glTexParameteri(target, GL_TEXTURE_MIN_FILTER, minFilter.GLint)
    glTexParameteri(target, GL_TEXTURE_MAG_FILTER, magFilter.GLint)

    add(cache, result)

proc setPixels(t: Texture,
               format: GLenum,
               dataType: GLenum,
               pixels: pointer) =
    glTexImage2D(
        t.target, 
        0.GLint, 
        t.internalFormat.GLint, 
        t.width.GLsizei, 
        t.height.GLsizei, 
        0.GLint, 
        format, 
        dataType, 
        pixels
    )
    if not isNil(pixels) and (t.levels > 1 or t.minFilter in [GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR_MIPMAP_NEAREST, GL_NEAREST_MIPMAP_NEAREST, GL_NEAREST_MIPMAP_LINEAR]):
        glGenerateMipmap(t.target)

proc setFaces(t: Texture,
              format: GLenum,
              dataType: GLenum,
              faces: array[6, pointer]) =
    
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0.GLint, t.internalFormat.GLint, t.width.GLsizei, t.height.GLsizei, 0.GLint, format, dataType, faces[0])
    glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0.GLint, t.internalFormat.GLint, t.width.GLsizei, t.height.GLsizei, 0.GLint, format, dataType, faces[1])
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0.GLint, t.internalFormat.GLint, t.width.GLsizei, t.height.GLsizei, 0.GLint, format, dataType, faces[2])
    glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0.GLint, t.internalFormat.GLint, t.width.GLsizei, t.height.GLsizei, 0.GLint, format, dataType, faces[3])
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0.GLint, t.internalFormat.GLint, t.width.GLsizei, t.height.GLsizei, 0.GLint, format, dataType, faces[4])
    glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0.GLint, t.internalFormat.GLint, t.width.GLsizei, t.height.GLsizei, 0.GLint, format, dataType, faces[5])

    if t.levels > 1:
        glGenerateMipmap(t.target)

proc allocate*(t: Texture) =
    glTexStorage2D(
        t.target, 
        t.levels.GLsizei, 
        t.internalFormat, 
        t.width.GLsizei, 
        t.height.GLsizei
    )

proc getTextureParamText(p: GLenum): string =
    case p:
        of GL_NEAREST: "GL_NEAREST"
        of GL_LINEAR: "GL_LINEAR"
        of GL_CLAMP_TO_EDGE: "GL_CLAMP_TO_EDGE"
        of GL_REPEAT: "GL_REPEAT"
        of GL_MIRRORED_REPEAT: "GL_MIRRORED_REPEAT"
        of GL_LINEAR_MIPMAP_LINEAR: "GL_LINEAR_MIPMAP_LINEAR"
        of GL_LINEAR_MIPMAP_NEAREST: "GL_LINEAR_MIPMAP_NEAREST"
        of GL_NEAREST_MIPMAP_LINEAR: "GL_NEAREST_MIPMAP_LINEAR"
        of GL_NEAREST_MIPMAP_NEAREST: "GL_NEAREST_MIPMAP_NEAREST"
        else: &"{p.int}"

proc newTexture*(target: GLenum,
                 width, 
                 height: int, 
                 levels: int=1,
                 internalFormat: GLenum=GL_RGBA8,
                 wrapS=GL_CLAMP_TO_EDGE, wrapT=GL_CLAMP_TO_EDGE, wrapR=GL_CLAMP_TO_EDGE, minFilter=GL_NEAREST, magFilter=GL_NEAREST): Texture =
    echo "wrapS:", getTextureParamText(wrapS)
    echo "wrapT:", getTextureParamText(wrapT)
    echo "wrapR:", getTextureParamText(wrapR)
    echo "minFilter:", getTextureParamText(minFilter)
    echo "magFilter:", getTextureParamText(magFilter)
    result = createTexture(
        target,
        width, 
        height, 
        wrapS=wrapS, 
        wrapT=wrapT, 
        wrapR=wrapR, 
        minFilter=if levels > 1: GL_LINEAR_MIPMAP_LINEAR  else: minFilter, 
        magFilter=magFilter, 
        levels=levels,
        internalFormat=internalFormat
    )
        
proc extractFormats(bits: int, channels: int, hdr: bool): (GLenum, GLenum, GLenum) =
    var 
        format = case channels:
            of 1:
                GL_RED
            of 2:
                GL_RG
            of 3:
                GL_RGB
            else:
                GL_RGBA
        dataType = case bits:
            of 8:
                GL_UNSIGNED_BYTE
            of 16:
                GL_UNSIGNED_SHORT
            else:
                cGL_FLOAT
        internalFormat = case bits:
            of 8:
                case channels:
                    of 1:
                        GL_R8
                    of 3:
                        GL_RGB8
                    else:
                        GL_RGBA8
            of 16:
                case channels:
                    of 1:
                        if hdr: GL_R16F else: GL_R16UI
                    of 3:
                        if hdr: GL_RGB16F else: GL_RGB16UI
                    else:
                        if hdr: GL_RGBA16F else: GL_RGBA16UI
            else:
                case channels:
                    of 1:
                        if hdr: GL_R32F else: GL_R32UI
                    of 3:
                        if hdr: GL_RGB32F else: GL_RGB32UI
                    else:
                        if hdr: GL_RGBA32F else: GL_RGBA32UI

    result = (internalFormat, format, dataType)

proc newTexture2D*(width, 
                   height: int, 
                   levels: int=1,
                   internalFormat: GLenum=GL_RGBA8,
                   format: GLenum=GL_RGBA,
                   dataType: GLenum=GL_UNSIGNED_BYTE,
                   pixels: pointer=nil,
                   wrapS=GL_CLAMP_TO_EDGE, wrapT=GL_CLAMP_TO_EDGE, wrapR=GL_CLAMP_TO_EDGE, minFilter=GL_NEAREST, magFilter=GL_NEAREST): Texture = 
    result = newTexture(
        target=GL_TEXTURE_2D,
        width=width,
        height=height,  
        levels=levels,
        internalFormat=internalFormat,
        wrapS=wrapS,
        wrapT=wrapT,
        wrapR=wrapR,
        minFilter=minFilter,
        magFilter=magFilter
    )
    if not isNil(pixels):
        setPixels(result, format, dataType, pixels)

proc newTexture2D*(width, 
                   height: int, 
                   bits: int, 
                   channels: int, 
                   hdr: bool,
                   pixels: pointer,
                   wrapS=GL_CLAMP_TO_EDGE, wrapT=GL_CLAMP_TO_EDGE, wrapR=GL_CLAMP_TO_EDGE, minFilter=GL_NEAREST, magFilter=GL_NEAREST): Texture =
    let (internalFormat, format, dataType) = extractFormats(bits, channels, hdr)
    result = newTexture2D(
        width, 
        height, 
        levels=1,
        internalFormat=internalFormat,
        format=format,
        dataType=dataType,
        pixels=pixels,
        wrapS=wrapS,
        wrapT=wrapT,
        wrapR=wrapR,
        minFilter=minFilter,
        magFilter=magFilter        
    )

proc newCubeTexture*(width, 
                     height: int, 
                     levels: int=1,
                     internalFormat: GLenum=GL_RGBA8,
                     format: GLenum=GL_RGBA,
                     dataType: GLenum=GL_UNSIGNED_BYTE,
                     wrapS=GL_CLAMP_TO_EDGE, wrapT=GL_CLAMP_TO_EDGE, wrapR=GL_CLAMP_TO_EDGE, minFilter=GL_NEAREST, magFilter=GL_NEAREST,
                     faces: array[6, pointer]): Texture =
    result = newTexture(
        target=GL_TEXTURE_CUBE_MAP,
        width=width,
        height=height, 
        levels=levels,
        internalFormat=internalFormat,
        wrapS=wrapS,
        wrapT=wrapT,
        wrapR=wrapR,
        minFilter=minFilter,
        magFilter=magFilter
    )
    echo &"* {width}x{height}"
    setFaces(result, format, dataType, faces)

proc newCubeTexture*(width, 
                     height: int, 
                     levels: int=1,
                     internalFormat: GLenum=GL_RGBA8,
                     wrapS=GL_CLAMP_TO_EDGE, wrapT=GL_CLAMP_TO_EDGE, wrapR=GL_CLAMP_TO_EDGE, minFilter=GL_NEAREST, magFilter=GL_NEAREST): Texture =
    result = newTexture(
        target=GL_TEXTURE_CUBE_MAP,
        width=width,
        height=height, 
        levels=levels,
        internalFormat=internalFormat,
        wrapS=wrapS,
        wrapT=wrapT,
        wrapR=wrapR,
        minFilter=minFilter,
        magFilter=magFilter
    )
    allocate(result)
    echo &"* cubemap of size {width}x{height} allocated."

proc newCubeTexture*(width, 
                     height: int, 
                     bits: int, 
                     channels: int, 
                     hdr: bool,
                     wrapS=GL_CLAMP_TO_EDGE, wrapT=GL_CLAMP_TO_EDGE, wrapR=GL_CLAMP_TO_EDGE, minFilter=GL_NEAREST, magFilter=GL_NEAREST,
                     faces: array[6, pointer]): Texture =
    let (internalFormat, format, dataType) = extractFormats(bits, channels, hdr)
    result = newCubeTexture(
        width, 
        height, 
        levels=1,
        internalFormat=internalFormat,
        format=format,
        dataType=dataType,
        wrapS=wrapS,
        wrapT=wrapT,
        wrapR=wrapR,
        minFilter=minFilter,
        magFilter=magFilter,
        faces=faces
    )

proc newTexture*(color: Color): Texture =
    var bytes = color.bytes
    result = newTexture2D(width=1, height=1, bits=8, channels=4, hdr=false, pixels=bytes.addr)

proc newTexture*(r: Resource, wrapS=GL_CLAMP_TO_EDGE, wrapT=GL_CLAMP_TO_EDGE, wrapR=GL_CLAMP_TO_EDGE, minFilter=GL_NEAREST, magFilter=GL_NEAREST): Texture = 
    if has(cache, r.url):
        result = get(cache, r.url)
    else:
        let image = cast[ImageResource](r)
        result = newTexture2D(
            width=image.width, 
            height=image.height, 
            bits=image.bits,
            channels=image.channels, 
            hdr=image.hdr,
            pixels=image.caddr,
            wrapS=wrapS,
            wrapT=wrapT,
            wrapR=wrapR,
            minFilter=minFilter,
            magFilter=magFilter
        )
        add(cache, r.url, result)

proc newTexture*(url: string, wrapS=GL_CLAMP_TO_EDGE, wrapT=GL_CLAMP_TO_EDGE, wrapR=GL_CLAMP_TO_EDGE, minFilter=GL_NEAREST, magFilter=GL_NEAREST): Texture = 
    let resource = load(url)
    result = newTexture(
        resource, 
        wrapS, 
        wrapT, 
        wrapR,
        minFilter, 
        magFilter,
    )

proc newCubeTexture*(px, nx, py, ny, pz, nz: string): Texture = 
    var 
        urls = [px, nx, py, ny, pz, nz]
        faces: array[6, pointer]
        width, height, channels, bits: int

    for i, url in pairs(urls):
        let r = load(url)
        let image = cast[ImageResource](r)
        faces[i] = image.caddr
        channels = image.channels
        bits = image.bits
        width = image.width
        height = image.height

    result = newCubeTexture(
        width=width.int32, 
        height=height.int32, 
        bits=bits, 
        channels=channels, 
        hdr=false, 
        faces=faces
    )

proc copy*(src, dst: Texture) =
    if src.target == dst.target:
        let depth = if src.target == GL_TEXTURE_CUBE_MAP: 6 else: 1
        glCopyImageSubData(
            src.buffer, 
            src.target, 
            0.GLint, 
            0.GLint, 
            0.GLint, 
            0.GLint, 
            dst.buffer, 
            dst.target, 
            0.GLint, 
            0.GLint, 
            0.GLint, 
            0.GLint, 
            src.width.GLsizei, 
            src.height.GLsizei, 
            depth.GLsizei
        )

proc mipmap*(t: Texture) =
    if t.levels > 1:
        glBindTexture(t.target, t.buffer)
        glGenerateMipmap(t.target)

proc params*(t: Texture, param: GLenum, value: GLenum) =
    glTexParameteri(t.target, param, value.GLint)

proc use*(t: Texture, slot: int) = 
    glActiveTexture((GL_TEXTURE0.int + slot).GLenum)
    if t != nil:
        glBindTexture(t.target, t.buffer)
    else:
        glBindTexture(GL_TEXTURE_2D, 0)

proc useForOutput*(t: Texture, slot: int, levels: int, layered=false) = 
    glBindImageTexture(
        slot.GLuint, 
        t.buffer, 
        levels.GLint, 
        if layered: GL_TRUE.GLboolean else: GL_FALSE.GLboolean, 
        0.GLint, 
        GL_WRITE_ONLY, 
        t.internalFormat
    )

proc destroy*(t: Texture) = remove(cache, t)
proc cleanupTextures*() = 
    if len(cache) > 0:
        echo &"Cleaning up [{len(cache)}] textures..."
        clear(cache)
