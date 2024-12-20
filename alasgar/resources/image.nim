import strformat
import base64

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
        hdr*: bool
        pixels*: seq[byte]
        bits*: int

#setFlipVerticallyOnLoad(false)

proc prepareBuffer(url: string): string =
    if startsWith(url, "data:image/"):
        let data = split(url, "base64,")
        result = decode(data[1])
    else:
        result = readAsset(url)

proc loadImage*(byteSeq: var seq[byte], r: ImageResource) =
    r.pixels = loadFromMemory(
        byteSeq, 
        r.width, 
        r.height, 
        r.channels, 
        stbi.Default
    )
    r.bits = 8 * (len(r.pixels) / (r.width * r.height * r.channels)).int

proc loadImage(url: string): Resource =
    var 
        r = new(ImageResource)
        buffer = prepareBuffer(url)
        byteSeq = toSeq(buffer.mapIt(it.byte))
    
    loadImage(byteSeq, r)
    r.hdr = url.endsWith(".hdr")
    if not startsWith(url, "data:image/"):
        echo &"Image [{url}] loaded with image with size [{r.width}x{r.height}] in [{r.channels}] channels and [{r.bits}] bpp."
    else:
        let t = url[0..16]
        echo &"Image [{t}...] loaded with image with size [{r.width}x{r.height}] in [{r.channels}] channels and [{r.bits}] bpp."
    result = r

proc destroyImage(r: Resource) =
    var ir = cast[ImageResource](r)
    clear(ir.pixels)
    ir.width = 0
    ir.height = 0
    ir.channels = 0

proc caddr*(t: ImageResource): pointer =
    result = t.pixels[0].addr

registerResourceManager("hdr", loadImage, destroyImage)
registerResourceManager("png", loadImage, destroyImage)
registerResourceManager("jpg", loadImage, destroyImage)
registerResourceManager("jpeg", loadImage, destroyImage)
registerResourceManager("tga", loadImage, destroyImage)
registerResourceManager("gif", loadImage, destroyImage)
registerResourceManager("bmp", loadImage, destroyImage)
registerResourceManager("psd", loadImage, destroyImage)
registerResourceManager("pic", loadImage, destroyImage)
