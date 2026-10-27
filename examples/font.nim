import alasgar

# Monogram: https://datagoblin.itch.io/monogram
# This is a raw 8-bit grayscale atlas, not a PNG or a TrueType font.
# Glyphs occupy 6x12 cells, laid out left to right in 16 columns.
const MonogramPixels = staticRead("assets/monogram.r8")

proc load() =
  # Create font textures only after the graphics context is ready.
  graphics.text.font = graphics.font(
    MonogramPixels,
    glyphWidth = 6,
    glyphHeight = 12,
    firstGlyph = ' '.ord,
    lastGlyph = '~'.ord,
    columns = 16,
  )
  graphics.color = vec4(0.04, 0.05, 0.08, 1.0)

proc draw() =
  graphics.text.draw("[gold]Custom font (Monogram 6x12)", vec2(24, 64))
  graphics.text.draw("ABCDEFGHIJKLMNOPQRSTUVWXYZ", vec2(24, 88))
  graphics.text.draw("abcdefghijklmnopqrstuvwxyz 0123456789", vec2(24, 108))
  graphics.text.draw("[lime]Colors [white]and [b]bold[/b] [i]italic[/i] work too!", vec2(24, 128))

proc cleanup() =
  # The custom atlas belongs to this example.
  destroy(graphics.text.font)

settings.exitOnEscape = true
window(800, 300, "Custom font sample", load, draw, cleanup)
