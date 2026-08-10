import std/[strformat, strutils]

import aljebra
import core
import text

func colorByte(value: float32): int =
  int(max(0.0'f32, min(1.0'f32, value)) * 255.0'f32 + 0.5'f32)

func colorTag(color: Vec4): string =
  &"[#{colorByte(color.x).toHex(2)}{colorByte(color.y).toHex(2)}{colorByte(color.z).toHex(2)}{colorByte(color.w).toHex(2)}]"

proc debug*(g: ptr Graphics, position = vec2(8, 8), color = vec4(0.5, 1.0, 0.4, 1.0)) =
  let
    stats = runtime.stats
    size = g.size
    fps: float32 = runtime.fps
    ms = runtime.delta * 1000.0
    lines = [
      &"[lightgray]FPS: [lime]{fps:>5.1f}",
      &"[lightgray]FRAME MS: [gold]{ms:>5.2f}",
      &"[lightgray]FRAME: [cyan]{runtime.frames}",
      &"[lightgray] . DRAW CALLS: [orange]{stats.drawCalls}",
      &"[lightgray] . VERTICES: [deepskyblue]{stats.vertices}",
      &"[lightgray] . INDICES: [violet]{stats.indices}",
      &"[lightgray] . INSTANCES: [mediumspringgreen]{stats.instances}",
      &"[lightgray]WINDOW: [lightskyblue]{runtime.window.size.x}x{runtime.window.size.y}",
      &"[lightgray]SCREEN: [lightskyblue]{g.size.x}x{g.size.y}",
    ]

  g.text.draw(colorTag(color) & lines.join("\n"), position)
