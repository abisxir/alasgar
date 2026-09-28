import std/unicode
import ../core
import font

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


iterator blocks*(text: string, font: Font, baseColor: Color = rgb(1, 1, 1)): (int, Color, int, int) =
  var
    penX = 0
    penY = 0
    current = ""
    color = baseColor

  for codepoint, style in codepoints(text):
    if style.len > 0 and style != current:
      current = style
      color = style
    case codepoint
    of '\r'.ord:
      discard
    of '\n'.ord:
      penX = 0
      inc penY
    of '\t'.ord:
      penX += 4
    else:
      if codepoint >= font.firstGlyph and codepoint <= font.lastGlyph:
        let glyph = codepoint - font.firstGlyph
        yield (glyph, color, penX, penY)
      inc penX
