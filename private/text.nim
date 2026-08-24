import std/[unicode]

import sokol/shape as shape

import core, pipeline, shader, camera, texture, geometry
import umath/common as common
import shaders/text as textShader

const
  AtlasColumns = 16
  AtlasRows = 8
  GlyphWidth = 6
  GlyphHeight = 12
  GlyphAdvance = GlyphWidth
  GlyphLineAdvance = GlyphHeight
  FirstGlyph = ' '.ord
  LastGlyph = '~'.ord
  AtlasWidth = AtlasColumns * GlyphWidth
  AtlasHeight = AtlasRows * GlyphHeight
  MonogramPixels = staticRead("assets/monogram.r8")

type
  TextVertex = object
    position: Vec3
    uv: Vec2
  TextInstance = object
    offset: Vec3
    glyph: Vec2
    color: Vec4
  TextRenderer* = object
    pipeline: Pipeline
    atlas: Texture
    sampler: Sampler

var
  renderer: TextRenderer

proc load() =
  let
    vertices = [
      TextVertex(position: vec3(0, 0, 0), uv: vec2(0, 1)),
      TextVertex(position: vec3(GlyphWidth, 0, 0), uv: vec2(1, 1)),
      TextVertex(position: vec3(GlyphWidth, GlyphHeight, 0), uv: vec2(1, 0)),
      TextVertex(position: vec3(0, GlyphHeight, 0), uv: vec2(0, 0)),
    ]
    indices = [0'u16, 1, 2, 0, 2, 3]

  var pixels = newSeq[byte](MonogramPixels.len)
  for index, value in MonogramPixels:
    pixels[index] = value.byte

  renderer.atlas = graphics.texture(
    (AtlasWidth).uint32,
    (AtlasHeight).uint32,
    channels = 1,
    pixels = pixels[0].addr,
  )
  renderer.sampler = graphics.sampler(renderer.atlas, minFilter = tfNearest, magFilter = tfNearest)
  renderer.pipeline = pipeline(
    graphics,
    graphics.shader(textShader.vs, textShader.fs),
    vertices,
    indices,
  )

proc cleanup() =
  destroy(renderer.pipeline)
  destroy(renderer.sampler)
  destroy(renderer.atlas)

func glyphPixel(glyph, row, column: int): bool =
  let
    glyphX = glyph mod AtlasColumns
    glyphY = glyph div AtlasColumns
    x = glyphX * GlyphWidth + column
    y = glyphY * GlyphHeight + row
  MonogramPixels[y * AtlasWidth + x] != '\0'

iterator codepoints(text: string): (int, string) =
  var
    style: string
    tag: string
    inTag = false
    escaped = false

  for rune in text.runes:
    let codepoint = rune.int
    if escaped:
      if inTag:
        tag.add($rune)
      else:
        yield (codepoint, style)
      escaped = false
    elif codepoint == '\\'.ord:
      escaped = true
    elif inTag:
      if codepoint == ']'.ord:
        style = tag
        inTag = false
        tag.setLen(0)
      else:
        tag.add($rune)
    elif codepoint == '['.ord:
      inTag = true
    else:
      yield (codepoint, style)

proc createInstances(text: string, instances: var seq[TextInstance]) =
  var
    penX = 0
    penY = 0
    current = "#ffffffff"
    rgba: Color = current

  for codepoint, style in codepoints(text):
    if style.len > 0 and style != current:
      current = style
      rgba = style
    case codepoint
    of '\r'.ord:
      discard
    of '\n'.ord:
      penX = 0
      inc penY
    of '\t'.ord:
      penX += GlyphAdvance * 4
    else:
      if codepoint >= FirstGlyph and codepoint <= LastGlyph:
        let glyph = codepoint - FirstGlyph
        if glyph != 0:
          instances.add TextInstance(
            offset: vec3(penX * GlyphAdvance, -penY * GlyphLineAdvance, 0),
            glyph: vec2(glyph mod AtlasColumns, glyph div AtlasColumns),
            color: color4v(rgba),
          )
      inc penX

proc addPixel(geometry: var Geometry, x, y: float32, color: Color, transform: common.Mat4) =
  let first = geometry.vertices.len
  let vertex = proc (x, y: float32): shape.Vertex =
    let position = transform * vec3(x, y, 0)
    shape.Vertex(
      x: position.x,
      y: position.y,
      z: position.z,
      normal: 0,
      u: 0,
      v: 0,
      color: color,
    )
  geometry.vertices.add(vertex(x, y))
  geometry.vertices.add(vertex(x + 1, y))
  geometry.vertices.add(vertex(x + 1, y + 1))
  geometry.vertices.add(vertex(x, y + 1))
  geometry.indices.add([
    first.uint16, (first + 1).uint16, (first + 2).uint16,
    first.uint16, (first + 2).uint16, (first + 3).uint16
  ])

proc shape*(t: ptr TextRenderer, text: string, color: Color="white", transform: common.Mat4=mat4()): Geometry =
  ## Create static geometry with one quad for every lit font pixel.
  discard t

  var
    penX = 0
    penY = 0
    current = ""
    pixelColor: Color = color

  for codepoint, style in codepoints(text):
    if style.len > 0 and style != current:
      current = style
      pixelColor = style
    case codepoint
    of '\r'.ord:
      discard
    of '\n'.ord:
      penX = 0
      inc penY
    of '\t'.ord:
      penX += GlyphAdvance * 4
    else:
      if codepoint >= FirstGlyph and codepoint <= LastGlyph:
        let glyph = codepoint - FirstGlyph
        for row in 0..<GlyphHeight:
          for column in 0..<GlyphWidth:
            if glyphPixel(glyph, row, column):
              result.addPixel(
                (penX * GlyphAdvance + column).float32,
                (-penY * GlyphLineAdvance + GlyphHeight - row - 1).float32,
                pixelColor,
                transform,
              )
      inc penX


proc `text`*(g: ptr Graphics): ptr TextRenderer =
  discard g
  addr renderer

proc draw*(t: ptr TextRenderer, text: string, model: common.Mat4, camera: Camera) =
  ## Render text as instanced pixels using the supplied world transform and camera.
  var instances: seq[TextInstance]
  createInstances(text, instances)

  t.pipeline.shader.set("MODEL", model)
  t.pipeline.shader.set("ATLAS", t.sampler, 0)
  if instances.len > 0:
    graphics.render(t.pipeline, camera, instances)

proc draw*(t: ptr TextRenderer, text: string, position: Vec2) =
  ## Render text at a top-left-relative pixel position.
  let
    height = graphics.size.y.float32
    width = height * graphics.aspect
    camera = graphics.ortho(vec3(0, 0, 1), vec3(0, 0, 0), height, 0.1, 10.0)
    model = translate(vec3(
      -width * 0.5 + position.x,
      height * 0.5 - position.y - GlyphHeight.float32,
      0,
    ))
  t.draw(text, model, camera)


graphics.onLoad(load)
graphics.onCleanup(cleanup)
