import sokol/shape as shape

import ../[core, pipeline, shader, camera, geometry]
import ../umath/common as common
import ../shaders/text as textShader
import font, markup

type
  TextVertex = object
    position: Vec3
    uv: Vec2
  TextInstance = object
    offset: Vec3
    glyph: Vec2
    color: Vec4
    size: Vec2
    slant: float32
  TextRenderer* = object
    font*: Font
    pipeline: Pipeline
    instances: seq[TextInstance]

const
  FontPixels = staticRead("../assets/tamzen-10x20-bold.r8")
  FontColumns = 16
  ItalicSlant = 0.3'f32
  BoldOffset = 1.0'f32
  UnitQuad = [
    TextVertex(position: vec3(0, 0, 0), uv: vec2(0, 1)),
    TextVertex(position: vec3(1, 0, 0), uv: vec2(1, 1)),
    TextVertex(position: vec3(1, 1, 0), uv: vec2(1, 0)),
    TextVertex(position: vec3(0, 1, 0), uv: vec2(0, 0)),
  ]
  QuadIndices = [0'u16, 1, 2, 0, 2, 3]

var
  renderer: TextRenderer

proc load() =
  let
    GlyphWidth = 10
    GlyphHeight = 20

  renderer.font = graphics.font(FontPixels, GlyphWidth, GlyphHeight, ' '.ord, '~'.ord, FontColumns)
  renderer.pipeline = pipeline(
    graphics,
    graphics.shader(textShader.vs, textShader.fs),
    UnitQuad,
    QuadIndices,
  )

proc cleanup() =
  destroy(renderer.pipeline)
  destroy(renderer.font)

proc createInstances(text: string, font: Font, instances: var seq[TextInstance]) =
  for glyph, style, penX, penY in blocks(text, font):
    let
      offset = vec3(penX * font.glyphAdvance, -penY * font.glyphLineHeight, 0)
      cell = vec2(font.glyphWidth.float32, font.glyphHeight.float32)
      slant = (if style.italic: ItalicSlant else: 0.0'f32)
      color = color4v(style.color)
      atlas = vec2(glyph mod font.atlasColumns, glyph div font.atlasColumns)

    instances.add(
      TextInstance(offset: offset, glyph: atlas, color: color, size: cell, slant: slant)
    )
    if style.bold:
      instances.add(
        TextInstance(
          offset: offset + vec3(BoldOffset, 0, 0),
          glyph: atlas,
          color: color,
          size: cell,
          slant: slant,
        )
      )

proc shape*(t: ptr TextRenderer, text: string, color: Color=rgb(255, 255, 255), transform: common.Mat4=mat4()): Geometry =
  ## Create static geometry with one quad for every lit font pixel.
  for glyph, style, penX, penY in blocks(text, t.font, color):
    result += t.font.shape(glyph, style, penX, penY, transform)


proc `text`*(g: ptr Graphics): ptr TextRenderer =
  discard g
  addr renderer

proc draw*(t: ptr TextRenderer, text: string, model: common.Mat4, camera: Camera) =
  ## Render text as instanced pixels using the supplied world transform and camera.
  t.instances.setLen(0)
  createInstances(text, t.font, t.instances)

  t.pipeline.shader.set("MODEL", model)
  t.pipeline.shader.set("ATLAS_GRID", vec2(t.font.atlasColumns, t.font.atlasRows))
  t.pipeline.shader.set("ATLAS", t.font.atlas, 0)
  if t.instances.len > 0:
    graphics.render(t.pipeline, camera, t.instances)

proc draw*(t: ptr TextRenderer, text: string, position: Vec2) =
  ## Render text at a top-left-relative pixel position.
  let
    height = graphics.size.y.float32
    width = height * graphics.aspect
    camera = graphics.ortho(vec3(0, 0, 1), vec3(0, 0, 0), height, 0.1, 10.0)
    model = translate(vec3(
      -width * 0.5 + position.x,
      height * 0.5 - position.y - t.font.glyphHeight.float32,
      0,
    ))
  t.draw(text, model, camera)


graphics.onLoad(load)
graphics.onCleanup(cleanup)
