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

var cachedContainer = newCachedContainer[Texture](destroyTexture)

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
    if channels == 4:
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8.GLint, width.GLsizei, height.GLsizei, 0.GLint, GL_RGBA, GL_UNSIGNED_BYTE, pixels)
    elif channels == 3:
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8.GLint, width.GLsizei, height.GLsizei, 0.GLint, GL_RGB, GL_UNSIGNED_BYTE, pixels)
    glBindTexture(GL_TEXTURE_2D, 0)

    add(cachedContainer, result)

proc newTexture*(color: Color): Texture =
    var bytes = color.bytes
    result = newTexture(1, 1, bytes[0].addr)

proc newTexture*(r: Resource): Texture = 
    let image = cast[ImageResource](r)
    result = newTexture(image.width.int32, image.height.int32, image.caddr, image.channels)

proc newTexture*(url: string): Texture = 
    if not has(cachedContainer, url):
        let resource = load(url)
        result = newTexture(resource)
        add(cachedContainer, url, result)
    else:
        result = get(cachedContainer, url)

proc use*(t: Texture, slot: int) = 
    if t != nil:
        glActiveTexture((GL_TEXTURE0.int + slot).GLenum)
        glBindTexture(GL_TEXTURE_2D, t.buffer)
    else:
        glBindTexture(GL_TEXTURE_2D, 0)

proc destroy*(t: Texture) = remove(cachedContainer, t)
proc cleanupTextures*() = clear(cachedContainer)
