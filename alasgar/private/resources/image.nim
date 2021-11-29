import strformat

import stb_image/read as stbi

import ../assets
import ../utils
import resource

export resource

type
    ImageResource* = ref object of Resource
        width*: int
        height*: int
        channels*: int
        pixels*: seq[byte]

proc loadImage(url: string): Resource =
    var r = new(ImageResource)
    setFlipVerticallyOnLoad(true)
    var stream = openAssetStream(url)
    if stream == nil:
        halt &"Could not open [{url}]."
    var buffer = readAll(stream)
    var byteSeq = cast[seq[byte]](buffer)
    r.pixels = loadFromMemory(
        byteSeq, 
        r.width, 
        r.height, 
        r.channels, 
        stbi.Default
    )
    result = r


proc destroyImage(r: Resource) =
    var ir = cast[ImageResource](r)
    clear(ir.pixels)
    ir.width = 0
    ir.height = 0
    ir.channels = 0

proc caddr*(t: ImageResource): pointer =
    result = t.pixels[0].addr

registerResourceManager("png", loadImage, destroyImage)
registerResourceManager("jpg", loadImage, destroyImage)
registerResourceManager("jpeg", loadImage, destroyImage)
registerResourceManager("tga", loadImage, destroyImage)
registerResourceManager("gif", loadImage, destroyImage)
registerResourceManager("bmp", loadImage, destroyImage)
registerResourceManager("psd", loadImage, destroyImage)
registerResourceManager("pic", loadImage, destroyImage)
