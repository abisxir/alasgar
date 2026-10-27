## Console-style markup for bitmap text, following the python-rich syntax.
##
## A tag styles the text after it until a closing tag:
##
## - `[bold]`, `[b]`, `[italic]`, `[i]` turn an attribute on; `[not bold]`,
##   `[not b]`, `[not italic]`, `[not i]` turn one off.
## - Words combine inside one tag: `[bold italic]`, `[bold red]`, `[#ff8800]`.
## - Tags stack. `[/]` closes the most recent tag, `[/bold]` closes the most
##   recent tag that asks for the same style. `[none]` asks for nothing.
## - `\[` and `\\` render a literal bracket and backslash; any other `[` that
##   cannot start a tag is text.
##
## The renderer draws colors, bold, and italic only, so the rich attributes it
## cannot draw (`dim`, `underline`, `on <color>`, `link`, `@handlers`) abort
## with a message instead of rendering through silently.
##
## One deliberate difference to rich: when a tag and its opposite are open at
## the same time (`[bold][not bold]x[/bold]`), the innermost tag wins here,
## while rich's span order can give the style to the tag that closes first.

import std/[options, strformat, strutils, unicode]

import ../core
import ../utils
import font

const
  term = "which the bitmap text renderer cannot draw; use colors, bold, or italic"
  unsupportedAttributes = [
    "dim", "d", "underline", "u", "blink", "blink2", "reverse", "r",
    "conceal", "c", "strike", "s", "underline2", "uu", "frame", "encircle",
    "overline", "o",
  ]
  tagStarts = {'a' .. 'z', '#', '/', '@'}
    ## rich starts a tag on one of these and leaves every other bracket alone.

type
  StyleSpec = object
    ## What one tag asks for; unset fields keep the enclosing style.
    color: Option[Color]
    bold: Option[bool]
    italic: Option[bool]

func apply(spec: StyleSpec, style: var Style) =
  if spec.color.isSome:
    style.color = spec.color.get
  if spec.bold.isSome:
    style.bold = spec.bold.get
  if spec.italic.isSome:
    style.italic = spec.italic.get

func namedColor(name: string): Option[Color] =
  for entry in webColorMap:
    if name == entry[0]:
      return some(entry[1])

func hexColor(name: string): Option[Color] =
  if name.len - 1 notin [3, 4, 6, 8]:
    return
  for index in 1 ..< name.len:
    if name[index] notin HexDigits:
      return
  some(color(name))

func tagColor(word: string): Option[Color] =
  if word.startsWith("#"):
    hexColor(word)
  else:
    namedColor(word)

proc parseTag(body: string): StyleSpec =
  ## Parse a tag body such as `bold italic` or `not bold red`.
  if body == "none":
    return
  let words = strutils.splitWhitespace(body)
  var index = 0
  while index < words.len:
    let word = words[index].toLowerAscii()
    case word
    of "bold", "b":
      result.bold = some(true)
    of "italic", "i":
      result.italic = some(true)
    of "not":
      inc index
      if index >= words.len:
        halt &"Markup tag '[{body}]' needs an attribute after 'not'."
      case words[index].toLowerAscii()
      of "bold", "b":
        result.bold = some(false)
      of "italic", "i":
        result.italic = some(false)
      else:
        halt &"Markup tag '[{body}]' cannot turn off '{words[index]}'; only bold and italic can."
    of "on", "link":
      halt &"Markup tag '[{body}]' uses '{word}', {term}."
    else:
      if word in unsupportedAttributes:
        halt &"Markup tag '[{body}]' uses '{word}', {term}."
      let value = tagColor(word)
      if value.isNone:
        halt &"Markup tag '[{body}]' has an unknown color or style '{words[index]}'."
      result.color = value
    inc index

func lastMatch(stack: seq[StyleSpec], spec: StyleSpec): int =
  ## Index of the most recent tag asking for the same style, or -1.
  result = -1
  for index in countdown(stack.high, 0):
    if stack[index] == spec:
      return index

iterator codepoints(text: string, base: Style): (int, Style) =
  ## Yield every codepoint of `text` with the style in effect for it.
  var
    stack: seq[StyleSpec]
    style = base
    index = 0

  while index < text.len:
    let
      rune = runeAt(text, index)
      codepoint = rune.int
      size = rune.size
    var tagged = false

    if codepoint == '\\'.ord and index + size < text.len:
      let escaped = runeAt(text, index + size)
      if escaped.int == '['.ord or escaped.int == '\\'.ord:
        yield (escaped.int, style)
        index += size + escaped.size
        tagged = true
    elif codepoint == '['.ord:
      let
        start = index + size
        stop = if start < text.len: text.find(']', start) else: -1
      if start < text.len and text[start] in tagStarts and stop > start and
          '[' notin text[start ..< stop]:
        let tag = text[start ..< stop].strip()
        if tag.startsWith("/"):
          let name = tag[1 .. ^1].strip()
          if name.len == 0:
            if stack.len == 0:
              halt "Closing markup tag '[/]' has nothing to close."
            stack.setLen(stack.len - 1)
          else:
            let found = lastMatch(stack, parseTag(name))
            if found < 0:
              halt &"Closing markup tag '[/{name}]' does not match any open tag."
            stack.delete(found)
        elif tag.startsWith("@"):
          halt &"Markup tag '[{tag}]' uses a handler, {term}."
        else:
          stack.add(parseTag(tag))
        style = base
        for spec in stack:
          spec.apply(style)
        index = stop + 1
        tagged = true

    if not tagged:
      yield (codepoint, style)
      index += size

iterator blocks*(text: string, font: Font, baseColor: Color = rgb(255, 255, 255)): (int, Style, int, int) =
  ## Yield one entry per glyph: its index in the font, its style, and the pen
  ## position in glyph pixels.
  var
    penX = 0
    penY = 0

  for codepoint, style in codepoints(text, Style(color: baseColor)):
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
        yield (codepoint - font.firstGlyph, style, penX, penY)
      inc penX
