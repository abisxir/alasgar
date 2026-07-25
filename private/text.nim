import std/unicode

import core, pipeline, shader, camera, texture
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

  doAssert MonogramPixels.len == AtlasColumns * GlyphWidth * AtlasRows * GlyphHeight
  var pixels = newSeq[byte](MonogramPixels.len)
  for index, value in MonogramPixels:
    pixels[index] = value.byte

  renderer.atlas = graphics.texture(
    (AtlasColumns * GlyphWidth).uint32,
    (AtlasRows * GlyphHeight).uint32,
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


proc createInstances(text: string, instances: var seq[TextInstance]) =
  var
    penX = 0
    penY = 0

  for rune in text.runes:
    let codepoint = rune.int
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
            color: vec4(1),
          )
      inc penX


proc `text`*(g: ptr Graphics): ptr TextRenderer =
  discard g
  addr renderer

proc draw*(t: ptr TextRenderer, text: string, model: Mat4, camera: Camera) =
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
