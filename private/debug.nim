## Disclaimer: this debug overlay implementation was written by AI.

import std/[strformat, strutils]

import ports/opengl
import aljebra
import core
import shader
import pipeline
import shaders/debug as debugShader

type
  DebugVertex = object
    x, y: float32
    r, g, b, a: float32
  DebugRenderer = object
    initialized: bool
    shader: Shader
    vao, vbo: GLuint

var renderer = DebugRenderer(initialized: false)

const
  GlyphWidth = 5
  GlyphHeight = 7
  GlyphScale = 2.0'f32
  GlyphAdvance = 12.0'f32
  LineAdvance = 18.0'f32

proc glyphRows(ch: char): array[GlyphHeight, uint8] =
  case ch
  of '0': [0b01110'u8, 0b10001'u8, 0b10011'u8, 0b10101'u8, 0b11001'u8, 0b10001'u8, 0b01110'u8]
  of '1': [0b00100'u8, 0b01100'u8, 0b00100'u8, 0b00100'u8, 0b00100'u8, 0b00100'u8, 0b01110'u8]
  of '2': [0b01110'u8, 0b10001'u8, 0b00001'u8, 0b00010'u8, 0b00100'u8, 0b01000'u8, 0b11111'u8]
  of '3': [0b11110'u8, 0b00001'u8, 0b00001'u8, 0b01110'u8, 0b00001'u8, 0b00001'u8, 0b11110'u8]
  of '4': [0b00010'u8, 0b00110'u8, 0b01010'u8, 0b10010'u8, 0b11111'u8, 0b00010'u8, 0b00010'u8]
  of '5': [0b11111'u8, 0b10000'u8, 0b10000'u8, 0b11110'u8, 0b00001'u8, 0b00001'u8, 0b11110'u8]
  of '6': [0b01110'u8, 0b10000'u8, 0b10000'u8, 0b11110'u8, 0b10001'u8, 0b10001'u8, 0b01110'u8]
  of '7': [0b11111'u8, 0b00001'u8, 0b00010'u8, 0b00100'u8, 0b01000'u8, 0b01000'u8, 0b01000'u8]
  of '8': [0b01110'u8, 0b10001'u8, 0b10001'u8, 0b01110'u8, 0b10001'u8, 0b10001'u8, 0b01110'u8]
  of '9': [0b01110'u8, 0b10001'u8, 0b10001'u8, 0b01111'u8, 0b00001'u8, 0b00001'u8, 0b01110'u8]
  of 'A': [0b01110'u8, 0b10001'u8, 0b10001'u8, 0b11111'u8, 0b10001'u8, 0b10001'u8, 0b10001'u8]
  of 'C': [0b01111'u8, 0b10000'u8, 0b10000'u8, 0b10000'u8, 0b10000'u8, 0b10000'u8, 0b01111'u8]
  of 'D': [0b11110'u8, 0b10001'u8, 0b10001'u8, 0b10001'u8, 0b10001'u8, 0b10001'u8, 0b11110'u8]
  of 'E': [0b11111'u8, 0b10000'u8, 0b10000'u8, 0b11110'u8, 0b10000'u8, 0b10000'u8, 0b11111'u8]
  of 'F': [0b11111'u8, 0b10000'u8, 0b10000'u8, 0b11110'u8, 0b10000'u8, 0b10000'u8, 0b10000'u8]
  of 'H': [0b10001'u8, 0b10001'u8, 0b10001'u8, 0b11111'u8, 0b10001'u8, 0b10001'u8, 0b10001'u8]
  of 'I': [0b01110'u8, 0b00100'u8, 0b00100'u8, 0b00100'u8, 0b00100'u8, 0b00100'u8, 0b01110'u8]
  of 'L': [0b10000'u8, 0b10000'u8, 0b10000'u8, 0b10000'u8, 0b10000'u8, 0b10000'u8, 0b11111'u8]
  of 'M': [0b10001'u8, 0b11011'u8, 0b10101'u8, 0b10101'u8, 0b10001'u8, 0b10001'u8, 0b10001'u8]
  of 'N': [0b10001'u8, 0b11001'u8, 0b10101'u8, 0b10011'u8, 0b10001'u8, 0b10001'u8, 0b10001'u8]
  of 'O': [0b01110'u8, 0b10001'u8, 0b10001'u8, 0b10001'u8, 0b10001'u8, 0b10001'u8, 0b01110'u8]
  of 'P': [0b11110'u8, 0b10001'u8, 0b10001'u8, 0b11110'u8, 0b10000'u8, 0b10000'u8, 0b10000'u8]
  of 'R': [0b11110'u8, 0b10001'u8, 0b10001'u8, 0b11110'u8, 0b10100'u8, 0b10010'u8, 0b10001'u8]
  of 'S': [0b01111'u8, 0b10000'u8, 0b10000'u8, 0b01110'u8, 0b00001'u8, 0b00001'u8, 0b11110'u8]
  of 'T': [0b11111'u8, 0b00100'u8, 0b00100'u8, 0b00100'u8, 0b00100'u8, 0b00100'u8, 0b00100'u8]
  of 'V': [0b10001'u8, 0b10001'u8, 0b10001'u8, 0b10001'u8, 0b10001'u8, 0b01010'u8, 0b00100'u8]
  of 'W': [0b10001'u8, 0b10001'u8, 0b10001'u8, 0b10101'u8, 0b10101'u8, 0b10101'u8, 0b01010'u8]
  of 'X': [0b10001'u8, 0b10001'u8, 0b01010'u8, 0b00100'u8, 0b01010'u8, 0b10001'u8, 0b10001'u8]
  of ':': [0b00000'u8, 0b00100'u8, 0b00100'u8, 0b00000'u8, 0b00100'u8, 0b00100'u8, 0b00000'u8]
  of '.': [0b00000'u8, 0b00000'u8, 0b00000'u8, 0b00000'u8, 0b00000'u8, 0b01100'u8, 0b01100'u8]
  of ' ': [0b00000'u8, 0b00000'u8, 0b00000'u8, 0b00000'u8, 0b00000'u8, 0b00000'u8, 0b00000'u8]
  else: [0b11111'u8, 0b10001'u8, 0b00010'u8, 0b00100'u8, 0b00100'u8, 0b00000'u8, 0b00100'u8]

proc addQuad(vertices: var seq[DebugVertex], x, y, w, h: float32, color: Vec4) =
  let
    x0 = x
    y0 = y
    x1 = x + w
    y1 = y + h
  vertices.add DebugVertex(x: x0, y: y0, r: color.x, g: color.y, b: color.z, a: color.w)
  vertices.add DebugVertex(x: x1, y: y0, r: color.x, g: color.y, b: color.z, a: color.w)
  vertices.add DebugVertex(x: x1, y: y1, r: color.x, g: color.y, b: color.z, a: color.w)
  vertices.add DebugVertex(x: x0, y: y0, r: color.x, g: color.y, b: color.z, a: color.w)
  vertices.add DebugVertex(x: x1, y: y1, r: color.x, g: color.y, b: color.z, a: color.w)
  vertices.add DebugVertex(x: x0, y: y1, r: color.x, g: color.y, b: color.z, a: color.w)

proc addText(vertices: var seq[DebugVertex], text: string, x, y: float32, color: Vec4) =
  var penX = x
  for ch in text:
    let rows = glyphRows(toUpperAscii(ch))
    for row in 0 ..< GlyphHeight:
      for col in 0 ..< GlyphWidth:
        if (rows[row] and (1'u8 shl (GlyphWidth - 1 - col))) != 0:
          vertices.addQuad(
            penX + col.float32 * GlyphScale,
            y + row.float32 * GlyphScale,
            GlyphScale,
            GlyphScale,
            color
          )
    penX += GlyphAdvance

proc initRenderer(g: ptr Graphics) =
  if renderer.initialized:
    return
  renderer.shader = g.shader(debugShader.vs, debugShader.fs)
  glGenVertexArrays(1, renderer.vao.addr)
  glBindVertexArray(renderer.vao)
  glGenBuffers(1, renderer.vbo.addr)
  glBindBuffer(GL_ARRAY_BUFFER, renderer.vbo)
  glBufferData(GL_ARRAY_BUFFER, 0.GLsizeiptr, nil, GL_DYNAMIC_DRAW)
  glVertexAttribPointer(0.GLuint, 2.GLint, cGL_FLOAT, false, sizeof(DebugVertex).GLsizei, cast[pointer](0))
  glEnableVertexAttribArray(0.GLuint)
  glVertexAttribPointer(1.GLuint, 4.GLint, cGL_FLOAT, false, sizeof(DebugVertex).GLsizei, cast[pointer](2 * sizeof(float32)))
  glEnableVertexAttribArray(1.GLuint)
  glBindVertexArray(0)
  glBindBuffer(GL_ARRAY_BUFFER, 0)
  renderer.initialized = true

proc debug*(g: ptr Graphics, position = vec2(8, 8), color = vec4(0.5, 1.0, 0.4, 1.0)) =
  ## Draw frame statistics as an on-screen overlay.
  initRenderer(g)

  let
    stats = runtime.stats
    size = g.size
    fps: float32 = runtime.fps
    ms = runtime.delta * 1000.0
    lines = [
      &"FPS: {fps:>5.1f}",
      &"FRAME MS: {ms:>5.2f}",
      &"FRAME: {runtime.frames}",
      &" . DRAW CALLS: {stats.drawCalls}",
      &" . VERTICES: {stats.vertices}",
      &" . INDICES: {stats.indices}",
      &" . INSTANCES: {stats.instances}",
      &"WINDOW: {size.x}X{size.y}",
    ]

  var vertices = newSeq[DebugVertex]()
  vertices.addQuad(
    position.x - 4.0'f32,
    position.y - 4.0'f32,
    260.0'f32,
    lines.len.float32 * LineAdvance + 8.0'f32,
    vec4(0.0, 0.0, 0.0, 0.65)
  )
  for index, line in lines:
    vertices.addText(line, position.x, position.y + index.float32 * LineAdvance, color)

  glDisable(GL_DEPTH_TEST)
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  use(renderer.shader)
  renderer.shader["VIEW_SIZE"] = vec2(size)
  glBindVertexArray(renderer.vao)
  glBindBuffer(GL_ARRAY_BUFFER, renderer.vbo)
  glBufferData(GL_ARRAY_BUFFER, (vertices.len * sizeof(DebugVertex)).GLsizeiptr, vertices[0].addr, GL_DYNAMIC_DRAW)
  glDrawArrays(GL_TRIANGLES, 0, vertices.len.GLsizei)
  glBindVertexArray(0)
  glBindBuffer(GL_ARRAY_BUFFER, 0)
