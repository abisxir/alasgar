import hashes
import tables
import ports/opengl

import image
import utils

type
    TextureObject = object
        buffer: GLuint
        width*: int32
        height*: int32
        ratio*: Vec2

    Texture* = ref TextureObject

var cache = initTable[string, Texture]()

proc hash*(t: Texture): Hash = 
    if t != nil:
        int(t.buffer)
    else:
        0

#proc `=destroy`*(t: var TextureObject) =
#    if t.buffer != 0:
#        glDeleteTextures(1, t.buffer.addr)
#        t.buffer = 0

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

proc newTexture*(color: Color): Texture =
    var bytes = color.bytes
    result = newTexture(1, 1, bytes[0].addr)

proc newTexture*(image: Image): Texture = newTexture(image.width.int32, image.height.int32, image.caddr, image.channels)


proc newTexture*(image: string): Texture = 
    if not cache.hasKey(image):
        cache[image] = newTexture(loadImage(image))
    result = cache[image]

proc use*(t: Texture, slot: int) = 
    if t != nil:
        glActiveTexture((GL_TEXTURE0.int + slot).GLenum)
        glBindTexture(GL_TEXTURE_2D, t.buffer)
    else:
        glBindTexture(GL_TEXTURE_2D, 0)

proc destroy*(t: Texture) =
    if t.buffer != 0:
        glDeleteTextures(1, t.buffer.addr)
        t.buffer = 0 


