import strformat

import ../[core, texture, utils]

type
  Font* = object
    glyphWidth*: int
    glyphHeight*: int
    firstGlyph*: int
    lastGlyph*: int
    columns*: int
      ## Number of glyph cells per atlas row.
    rows*: int
      ## Number of glyph cell rows in the atlas.
    pixels: seq[byte]
    texture: Texture
    sampler: Sampler

func `atlas`*(f: Font): Sampler = f.sampler
func `glyphAdvance`*(f: Font): int = f.glyphWidth
func `glyphLineHeight`*(f: Font): int = f.glyphHeight

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
  if columns <= 0:
    halt "Font atlas needs at least one column."

  let
    cellSize = glyphWidth * glyphHeight
    rows = pixels.len div columns div cellSize

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

func pixel*(f: Font, glyph, row, column: int): bool =
  let
    x = (glyph mod f.columns) * f.glyphWidth + column
    y = (glyph div f.columns) * f.glyphHeight + row
  f.pixels[y * f.columns * f.glyphWidth + x] != 0

proc destroy*(font: var Font) =
  destroy(font.sampler)
  destroy(font.texture)
