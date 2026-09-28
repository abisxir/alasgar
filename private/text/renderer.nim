import sokol/shape as shape

import ../[core, pipeline, shader, camera, geometry]
import ../umath/common as common
import ../shaders/text as textShader
import font, markup

const
  MonogramPixels = staticRead("../assets/monogram.r8")
  MonogramColumns = 16

type
  TextVertex = object
    position: Vec3
    uv: Vec2
  TextInstance = object
    offset: Vec3
    glyph: Vec2
    color: Vec4
    size: Vec2
  TextRenderer* = object
    font: Font
    pipeline: Pipeline
    instances: seq[TextInstance]

# Glyph quad in unit space. `INSTANCE_SIZE` scales it to the cell size of the
# font being drawn, so one pipeline serves fonts of any glyph size.
const
  UnitQuad = [
    TextVertex(position: vec3(0, 0, 0), uv: vec2(0, 1)),
    TextVertex(position: vec3(1, 0, 0), uv: vec2(1, 1)),
    TextVertex(position: vec3(1, 1, 0), uv: vec2(1, 0)),
    TextVertex(position: vec3(0, 1, 0), uv: vec2(0, 0)),
  ]
  QuadIndices = [0'u16, 1, 2, 0, 2, 3]

var
  renderer: TextRenderer
  loaded: bool

proc load() =
  let
    GlyphWidth = 6
    GlyphHeight = 12

  renderer.font = graphics.font(MonogramPixels, GlyphWidth, GlyphHeight, ' '.ord, '~'.ord, MonogramColumns)
  renderer.pipeline = pipeline(
    graphics,
    graphics.shader(textShader.vs, textShader.fs),
    UnitQuad,
    QuadIndices,
  )
  loaded = true

proc ensureLoaded() =
  ## Initialize the font and the glyph pipeline on first use.
  ##
  ## Applications call `graphics.text.shape` from their `load` callback, which
  ## runs before `graphics.onLoad` callbacks, so the renderer cannot rely on a
  ## startup callback having run already.
  if not loaded:
    load()

proc cleanup() =
  destroy(renderer.pipeline)
  destroy(renderer.font)
  loaded = false

proc createInstances(text: string, font: Font, instances: var seq[TextInstance]) =
  for glyph, color, penX, penY in blocks(text, font):
    instances.add(
      TextInstance(
        offset: vec3(penX * font.glyphAdvance, -penY * font.glyphLineHeight, 0),
        glyph: vec2(glyph mod font.columns, glyph div font.columns),
        color: color4v(color),
        size: vec2(font.glyphWidth.float32, font.glyphHeight.float32),
      )
    )

proc addPixel(geometry: var Geometry, x, y: float32, color: Color, transform: common.Mat4) =
  template vertex(px, py: float32): shape.Vertex =
    let position = transform * vec3(px, py, 0)
    shape.Vertex(
      x: position.x,
      y: position.y,
      z: position.z,
      normal: 0,
      u: 0,
      v: 0,
      color: color,
    )
  let first = geometry.vertices.len
  geometry.vertices.add(vertex(x, y))
  geometry.vertices.add(vertex(x + 1, y))
  geometry.vertices.add(vertex(x + 1, y + 1))
  geometry.vertices.add(vertex(x, y + 1))
  geometry.indices.add([
    first.uint16, (first + 1).uint16, (first + 2).uint16,
    first.uint16, (first + 2).uint16, (first + 3).uint16
  ])

proc shape*(t: ptr TextRenderer, text: string, color: Color=rgb(1, 1, 1), transform: common.Mat4=mat4()): Geometry =
  ## Create static geometry with one quad for every lit font pixel.
  ensureLoaded()
  for glyph, pixelColor, penX, penY in blocks(text, t.font, color):
    for row in 0..<t.font.glyphHeight:
      for column in 0..<t.font.glyphWidth:
        if t.font.pixel(glyph, row, column):
          result.addPixel(
            (penX * t.font.glyphAdvance + column).float32,
            (-penY * t.font.glyphLineHeight + t.font.glyphHeight - row - 1).float32,
            pixelColor,
            transform,
          )


proc `text`*(g: ptr Graphics): ptr TextRenderer =
  discard g
  addr renderer

proc draw*(t: ptr TextRenderer, text: string, model: common.Mat4, camera: Camera) =
  ## Render text as instanced pixels using the supplied world transform and camera.
  ensureLoaded()
  t.instances.setLen(0)
  createInstances(text, t.font, t.instances)

  t.pipeline.shader.set("MODEL", model)
  t.pipeline.shader.set("ATLAS_GRID", vec2(t.font.columns, t.font.rows))
  t.pipeline.shader.set("ATLAS", t.font.atlas, 0)
  if t.instances.len > 0:
    graphics.render(t.pipeline, camera, t.instances)

proc draw*(t: ptr TextRenderer, text: string, position: Vec2) =
  ## Render text at a top-left-relative pixel position.
  ensureLoaded()
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


graphics.onCleanup(cleanup)
