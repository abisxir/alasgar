import strformat

import ../[core, texture, utils, geometry]

type
  Font* = object
    glyphWidth: int
    glyphHeight: int
    firstGlyph: int
    lastGlyph: int
    columns: int
    rows: int
    pixels: seq[byte]
    texture: Texture
    sampler: Sampler
  Style* = object
    ## Fully resolved style of a glyph.
    color*: Color
    bold*: bool
    italic*: bool

const
  ItalicSlant = 0.3'f32
  BoldOffset = 1.0'f32


func `atlas`*(f: Font): Sampler = f.sampler
func `glyphAdvance`*(f: Font): int = f.glyphWidth
func `glyphLineHeight`*(f: Font): int = f.glyphHeight
func `glyphWidth`*(f: Font): int = f.glyphWidth
func `glyphHeight`*(f: Font): int = f.glyphHeight
func `firstGlyph`*(f: Font): int = f.firstGlyph
func `lastGlyph`*(f: Font): int = f.lastGlyph
func `atlasColumns`*(f: Font): int = f.columns
func `atlasRows`*(f: Font): int = f.rows

proc font*(
  g: ptr Graphics,
  pixels: string,
  glyphWidth, glyphHeight, firstGlyph, lastGlyph, columns: int,
): Font =
  ## Create a bitmap font from a raw 8-bit atlas that stores its glyphs in a
  ## grid of `columns` cells per row.
  ##
  ## `pixels` must hold exactly `columns * rows * glyphWidth * glyphHeight`
  ## bytes, so the row count and the atlas texture size are derived from the
  ## font data instead of being fixed by the engine. Cells behind `lastGlyph`
  ## may stay empty. A layout that does not tile the pixel data aborts with a
  ## message, because such a font cannot be sampled correctly.
  if glyphWidth <= 0 or glyphHeight <= 0:
    halt "Font glyph cells need a positive size."

  let
    cellSize = glyphWidth * glyphHeight
    rows = pixels.len div columns div cellSize

  echo "calculated columns: ", columns

  if rows <= 0 or pixels.len != columns * rows * cellSize:
    halt &"Font atlas of {pixels.len} bytes does not fill {columns} columns of {glyphWidth}x{glyphHeight} cells."
  if lastGlyph - firstGlyph + 1 > columns * rows:
    halt &"Font glyph range {firstGlyph}..{lastGlyph} does not fit a {columns}x{rows} atlas."

  result.pixels.setLen(pixels.len)
  for index, value in pixels:
    result.pixels[index] = value.byte
  result.texture = g.texture(
    (columns * glyphWidth).uint32,
    (rows * glyphHeight).uint32,
    channels = 1,
    pixels = result.pixels[0].addr,
  )
  result.sampler = g.sampler(result.texture, minFilter = tfNearest, magFilter = tfNearest)
  result.glyphWidth = glyphWidth
  result.glyphHeight = glyphHeight
  result.firstGlyph = firstGlyph
  result.lastGlyph = lastGlyph
  result.columns = columns
  result.rows = rows

func isPixelSet*(f: Font, glyph, row, column: int): bool =
  let
    x = (glyph mod f.columns) * f.glyphWidth + column
    y = (glyph div f.columns) * f.glyphHeight + row
  f.pixels[y * f.columns * f.glyphWidth + x] != 0

proc addPixel(
  geometry: var Geometry,
  x, y, baseline: float32,
  color: Color,
  transform: common.Mat4,
  slant: float32,
) =
  # `baseline` is the bottom of the glyph cell: the shear leans the glyph above
  # it, exactly like `INSTANCE_SLANT` does in the instanced pipeline.
  template vertex(px, py: float32): Vertex =
    let position = transform * vec3(px + (py - baseline) * slant, py, 0)
    Vertex(
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

func shape*(font: Font, glyph: int, style: Style, penX, penY: int, transform: Mat4): Geometry =
  let
    baseline = -penY * font.glyphLineHeight
    slant = (if style.italic: ItalicSlant else: 0.0'f32)
  for row in 0..<font.glyphHeight:
    for column in 0..<font.glyphWidth:
      if font.isPixelSet(glyph, row, column):
        let
          x = (penX * font.glyphAdvance + column).float32
          y = (baseline + font.glyphHeight - row - 1).float32
        result.addPixel(x, y, baseline.float32, style.color, transform, slant)
        if style.bold:
          result.addPixel(x + BoldOffset, y, baseline.float32, style.color, transform, slant)

proc destroy*(font: var Font) =
  destroy(font.sampler)
  destroy(font.texture)
