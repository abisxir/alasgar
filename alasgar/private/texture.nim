import hashes
import tables
import strutils
import ports/opengl

import resources/image
import utils
import container

type
    TextureObject = object
        buffer: GLuint
        width*: int32
        height*: int32
        ratio*: Vec2

    Texture* = ref TextureObject

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

proc newTexture*(width, height: int32, pixels: pointer, channels=4): Texture =
    new(result)
    result.width = width
    result.height = height
    result.ratio = vec2(1, height.float32 / width.float32)

    glGenTextures(1, result.buffer.addr)
    glBindTexture(GL_TEXTURE_2D, result.buffer)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

    var 
        internalFormat = GL_RGBA8.GLint
        format = GL_RGBA
    if channels == 3:
        internalFormat = GL_RGB8.GLint
        format = GL_RGB
    elif channels == 1:
        internalFormat = GL_R8.GLint
        format = GL_RED

    glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, width.GLsizei, height.GLsizei, 0.GLint, format, GL_UNSIGNED_BYTE, pixels)
    glBindTexture(GL_TEXTURE_2D, 0)

    add(cache, result)

proc newCubeTexture*(width, height: int32, internalformat=GL_RGBA16F, levels=0): Texture =
    new(result)
    result.width = width
    result.height = height
    result.ratio = vec2(1, height.float32 / width.float32)

    let mipmapLevels = if levels > 1: GL_LINEAR_MIPMAP_LINEAR.GLint else: GL_LINEAR.GLint

    glGenTextures(1, result.buffer.addr)
    glBindTexture(GL_TEXTURE_CUBE_MAP, result.buffer)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, mipmapLevels)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR.GLint)

    glTexImage2D(GL_TEXTURE_CUBE_MAP, levels.GLint, internalFormat.GLint, width.GLsizei, height.GLsizei, 0.GLint, GL_RGBA, GL_UNSIGNED_BYTE, cast[pointer](0))
    glBindTexture(GL_TEXTURE_CUBE_MAP, 0)

    add(cache, result)


proc newCubeTexture*(width, height: int32, faces: array[6, pointer], channels=4): Texture =
    new(result)
    result.width = width
    result.height = height
    result.ratio = vec2(1, height.float32 / width.float32)
    glGenTextures(1, result.buffer.addr)
    glBindTexture(GL_TEXTURE_CUBE_MAP, result.buffer)

    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR.GLint)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR.GLint)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE.GLint)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE.GLint)
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE.GLint)

    var 
        internalFormat = GL_RGBA8.GLint
        format = GL_RGBA
    if channels == 3:
        internalFormat = GL_RGB8.GLint
        format = GL_RGB
    elif channels == 1:
        internalFormat = GL_R8.GLint
        format = GL_RED

    for i in faces.low..faces.high:
        var 
            pixels = faces[i]
            target = (GL_TEXTURE_CUBE_MAP_POSITIVE_X.int + i).GLenum
        glTexImage2D(target, 0, internalFormat, width.GLsizei, height.GLsizei, 0.GLint, format, GL_UNSIGNED_BYTE, pixels)

    glBindTexture(GL_TEXTURE_2D, 0)

    add(cache, result)

proc newTexture*(color: Color): Texture =
    var bytes = color.bytes
    result = newTexture(1, 1, bytes[0].addr)

proc newTexture*(r: Resource): Texture = 
    if has(cache, r.url):
        result = get(cache, r.url)
    else:
        let image = cast[ImageResource](r)
        result = newTexture(image.width.int32, image.height.int32, image.caddr, image.channels)
        add(cache, r.url, result)

proc newTexture*(url: string): Texture = 
    let resource = load(url)
    result = newTexture(resource)

proc newCubeTexture*(px, nx, py, ny, pz, nz: string): Texture = 
    var 
        urls = [px, nx, py, ny, pz, nz]
        faces: array[6, pointer]
        width, height, channels: int

    for i, url in pairs(urls):
        let r = load(url)
        let image = cast[ImageResource](r)
        faces[i] = image.caddr
        channels = image.channels
        width = image.width
        height = image.height

    result = newCubeTexture(width.int32, height.int32, faces, channels)

proc use*(t: Texture, slot: int) = 
    glActiveTexture((GL_TEXTURE0.int + slot).GLenum)
    if t != nil:
        glBindTexture(GL_TEXTURE_2D, t.buffer)
    else:
        glBindTexture(GL_TEXTURE_2D, 0)

proc destroy*(t: Texture) = remove(cache, t)
proc cleanupTextures*() = 
    if len(cache) > 0:
        echo &"Cleaning up [{len(cache)}] textures..."
        clear(cache)
