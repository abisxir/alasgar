import strformat

import stb_image/read as stbi

import assets
import utils

type
    Image* = ref object
        width*: int
        height*: int
        channels*: int
        pixels*: seq[byte]


proc loadImage*(filename: string): Image =
    new(result)
    setFlipVerticallyOnLoad(true)
    var stream = openAssetStream(filename)
    if stream == nil:
        halt &"Could not open [{filename}]."
    var buffer = readAll(stream)
    var byteSeq = cast[seq[byte]](buffer)
    result.pixels = stbi.loadFromMemory(byteSeq, result.width, result.height, result.channels, stbi.Default)


proc caddr*(t: Image): pointer =
    result = t.pixels[0].addr