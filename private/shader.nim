## Shader runtime and the GLSL shader compiler.
##
## The main compiler was loosly based on shady, a nice work of treeform:
## https://github.com/treeform/shady
##
## There was an issue with using the deprecated `owner` function in newer
## versions of Nim. Since the existing implementation was mostly a shallow copy
## with only a few small fixes, I asked DeepSeek to rewrite it as a new module
## supporting only GL410 and ES300. Thus, the entire `glsl/*` implementation
## was rewritten with DeepSeek.
##
## `toGLSL` converts a shader proc (Nim typed AST) into GLSL source plus
## vertex attribute layout metadata (locations, sizes, instancing).
##
## The actual compiler lives in `private/glsl/`:
##
##  - `dsl.nim`      : DSL wrappers (Layout/Batch/Uniform, samplers).
##  - `builtins.nim` : single source of truth for GLSL names.
##  - `typeinfo.nim` : structural Nim->GLSL type mapping.
##  - `scope.nim`    : symbol resolution without the deprecated `owner`.
##  - `ir.nim`       : minimal intermediate representation.
##  - `capture.nim`  : typed AST -> IR.
##  - `emit.nim`     : IR -> GLSL source text.

import hashes
import strformat
import std/strutils
import tables
import macros

import ports/opengl
import texture
import utils
import aljebra
import camera

import glsl/dsl
import glsl/ir
import glsl/typeinfo
import glsl/capture
import glsl/emit

export aljebra, camera, dsl

type
  ShaderAttribute* = object
    typeName*: string
    index*: int
    size*: int
    instanced*: bool
    rows*: int
    columns*: int
    columnSize*: int

  ShaderLayout* = object
    attrs*: seq[ShaderAttribute]

  ShaderValueKind = enum
    svUint, svInt, svFloat, svVec2, svVec3, svVec4, svMat3, svMat4, svSampler
  ShaderParam = object
    case kind: ShaderValueKind
    of svUint:
      uintVal: uint32
    of svInt:
      intVal: int32
    of svFloat:
      floatVal: float32
    of svVec2:
      vec2Val: Vec2
    of svVec3:
      vec3Val: Vec3
    of svVec4:
      vec4Val: Vec4
    of svMat3:
      mat3Val: Mat3
    of svMat4:
      mat4Val: Mat4
    of svSampler:
      samplerVal: Sampler
    slot: int
  Shader* = object
    program*: GLuint
    layout*: ShaderLayout
    source*: string
    params: Table[string, ShaderParam]

proc destroy*(shader: var Shader) =
  if shader.program != 0:
    glDeleteProgram(shader.program)
    echo &"- Shader [{shader.program}] destroyed."
    shader.program = 0

proc hash*(o: Shader): Hash = int(o.program)

proc formatSource(source: string): string =
  for i, line in pairs(split(source, "\n")):
    add(result, &"{i:4} {line}\n")

proc isShaderCompiled(shader: GLuint): bool {.inline.} =
  var compiled: GLint
  glGetShaderiv(shader, GL_COMPILE_STATUS, addr compiled)
  result = GLboolean(compiled) == GLboolean(GL_TRUE)

proc shaderInfoLog(s: GLuint): string =
  var infoLen: GLint
  result = ""
  glGetShaderiv(s, GL_INFO_LOG_LENGTH, addr infoLen)
  if infoLen > 0:
    var infoLog: cstring = cast[cstring](alloc(infoLen + 1))
    glGetShaderInfoLog(s, infoLen, nil, infoLog)
    result = $infoLog
    dealloc(infoLog)

proc isProgramLinked(prog: GLuint): bool {.inline.} =
  var linked: GLint
  glGetProgramiv(prog, GL_LINK_STATUS, addr linked)
  result = GLboolean(linked) == GLboolean(GL_TRUE)

proc programInfoLog(s: GLuint): string =
  var infoLen: GLint
  result = ""
  glGetProgramiv(s, GL_INFO_LOG_LENGTH, addr infoLen)
  if infoLen > 0:
    var infoLog: cstring = cast[cstring](alloc(infoLen + 1))
    glGetProgramInfoLog(s, infoLen, nil, infoLog)
    result = $infoLog
    dealloc(infoLog)

proc loadShaderSource(src: cstring, kind: GLenum): GLuint =
  result = glCreateShader(kind)
  if result == 0:
    return 0

  # Load the shader source
  var srcArray = [src]
  glShaderSource(result, 1, cast[cstringArray](addr srcArray), nil)

  # Compile the shader
  glCompileShader(result)

  # Check the compile status
  let compiled = isShaderCompiled(result)
  let info = shaderInfoLog(result)
  if not compiled:
    echo formatSource(&"{src}")
    when defined(linux):
      writeFile("/tmp/error.glsl", &"{src}")
    logi "Shader compile error: ", info
    glDeleteShader(result)
  elif info.len > 0:
    logi "Shader compile log: ", info


proc createProgram*(vs, fs: string): GLuint =
  result = glCreateProgram()
  if result == 0:
    halt &"Could not create program: {glGetError().int}"
  let vShader = loadShaderSource(vs, GL_VERTEX_SHADER)
  if vShader == 0:
    glDeleteProgram(result)
    halt &"Could not create vertex shader: {glGetError().int}"

  glAttachShader(result, vShader)
  let fShader = loadShaderSource(fs, GL_FRAGMENT_SHADER)
  if fShader == 0:
    glDeleteProgram(result)
    halt &"Could not create fragment shader: {glGetError().int}"

  glAttachShader(result, fShader)

  #for a in attributes:
  #    glBindAttribLocation(result, a.index.GLuint, a.name.cstring)

  glLinkProgram(result)
  glDeleteShader(vShader)
  glDeleteShader(fShader)

  let linked = isProgramLinked(result)
  if not linked:
    halt &"Could not link: {programInfoLog(result)}"


proc getUniformLocation*(s: Shader, key: string): GLint =
  ## Get the location of a uniform variable in the shader program
  ##
  ## Returns -1 if the uniform is not found
  glGetUniformLocation(s.program, key)

proc getAttributeLocation*(s: Shader, key: string): GLint =
  ## Get the location of an attribute variable in the shader program
  ##
  ## Returns -1 if the attribute is not found
  glGetAttribLocation(s.program, key)

proc `[]=`*(s: Shader, key: string, value: Vec2) = glUniform2fv(getUniformLocation(s, key), 1, value.caddr)
proc `[]=`*(s: Shader, key: string, value: Vec3) = glUniform3fv(getUniformLocation(s, key), 1, value.caddr)
proc `[]=`*(s: Shader, key: string, value: Vec4) = glUniform4fv(getUniformLocation(s, key), 1, value.caddr)
proc `[]=`*(s: Shader, key: string, value: float32) = glUniform1f(getUniformLocation(s, key), value)
proc `[]=`*(s: Shader, key: string, value: int) = glUniform1i(getUniformLocation(s, key), value.GLint)
proc `[]=`*(s: Shader, key: string, value: uint32) = glUniform1ui(getUniformLocation(s, key), value.GLuint)
proc `[]=`*(s: Shader, key: string, value: Mat4) = glUniformMatrix4fv(getUniformLocation(s, key), 1, false, value.caddr)
proc `[]=`*(s: Shader, key: string, value: Mat3) = glUniformMatrix3fv(getUniformLocation(s, key), 1, false, value.caddr)
proc `[]=`*(s: Shader, key: string, value: Sampler) = discard

proc get*(shader: Shader, key: string, r: var uint32) = r = shader.params[key].uintVal
proc get*(shader: Shader, key: string, r: var int32) = r = shader.params[key].intVal
proc get*(shader: Shader, key: string, r: var int) = r = shader.params[key].intVal.int
proc get*(shader: Shader, key: string, r: var float32) = r = shader.params[key].floatVal
proc get*(shader: Shader, key: string, r: var Vec2) = r = shader.params[key].vec2Val
proc get*(shader: Shader, key: string, r: var Vec3) = r = shader.params[key].vec3Val
proc get*(shader: Shader, key: string, r: var Vec4) = r = shader.params[key].vec4Val
proc get*(shader: Shader, key: string, r: var Mat3) = r = shader.params[key].mat3Val
proc get*(shader: Shader, key: string, r: var Mat4) = r = shader.params[key].mat4Val
proc get*(shader: Shader, key: string, r: var Sampler) = r = shader.params[key].samplerVal

proc set*(shader: var Shader, key: string, value: uint32) =
  shader.params[key] = ShaderParam(
    kind: svUint,
    uintVal: value,
  )

proc set*(shader: var Shader, key: string, value: int32) =
  shader.params[key] = ShaderParam(
    kind: svInt,
    intVal: value
  )

proc set*(shader: var Shader, key: string, value: int) =
  set(shader, key, value.int32)

proc set*(shader: var Shader, key: string, value: float32) =
  shader.params[key] = ShaderParam(
    kind: svFloat,
    floatVal: value
  )

proc set*(shader: var Shader, key: string, value: Vec2) =
  shader.params[key] = ShaderParam(
    kind: svVec2,
    vec2Val: value
  )

proc set*(shader: var Shader, key: string, value: Vec3) =
  shader.params[key] = ShaderParam(
    kind: svVec3,
    vec3Val: value
  )

proc set*(shader: var Shader, key: string, value: Vec4) =
  shader.params[key] = ShaderParam(
    kind: svVec4,
    vec4Val: value
  )

proc set*(shader: var Shader, key: string, value: Mat4) =
  shader.params[key] = ShaderParam(
    kind: svMat4,
    mat4Val: value
  )

proc set*(shader: var Shader, key: string, value: Sampler, slot: int) =
  shader.params[key] = ShaderParam(
    kind: svSampler,
    samplerVal: value,
    slot: slot
  )

proc hasUniform*(shader: var Shader, name: string): bool = getUniformLocation(shader, name) >= 0

proc activate(shader: var Shader, sampler: Sampler, name: string, slot: int) =
  var location = getUniformLocation(shader, name)
  if location >= 0:
    glUniform1i(location, slot.GLint)
    use(sampler, slot)

proc update(shader: var Shader, key: string, p: ShaderParam) =
  case p.kind:
    of svUint: shader[key] = p.uintVal
    of svInt: shader[key] = p.intVal
    of svFloat: shader[key] = p.floatVal
    of svVec2: shader[key] = p.vec2Val
    of svVec3: shader[key] = p.vec3Val
    of svVec4: shader[key] = p.vec4Val
    of svMat3: shader[key] = p.mat3Val
    of svMat4: shader[key] = p.mat4Val
    of svSampler: activate(shader, p.samplerVal, key, p.slot)

proc use*(shader: var Shader) =
  glUseProgram(shader.program)
  for key, param in pairs(shader.params):
    update(shader, key, param)

proc emitCameraStruct(res: var string, def: NimNode) =
  ## Generates the CameraGLSL struct from the actual Nim type, so runtime
  ## writes (`GLSL_CAMERA.SCREEN_SIZE` etc.) can never drift from the
  ## shader source shape.
  var objTy = def
  while objTy.kind == nnkTypeDef:
    objTy = objTy[2]
  if objTy.kind == nnkObjectTy or objTy.kind == nnkRecList:
    let rex = if objTy.kind == nnkRecList: objTy else: objTy[^1]
    for prop in rex:
      if prop.kind == nnkIdentDefs:
        let nm = if prop[0].kind == nnkPostfix: prop[0][1]
          else: prop[0]
        let info = glslTypeOf(prop[1])
        res.add "\t"
        res.add info.glslName
        res.add " "
        res.add nm.strVal
        res.add ";\n"
  else:
    res.add "\tmat4 VIEW;\n\tmat4 PROJECTION;\n\tmat4 VIEW_PROJECTION;\n" &
      "\tmat4 INV_VIEW;\n\tmat4 INV_PROJECTION;\n\tmat4 INV_VIEW_PROJECTION;\n" &
      "\tvec3 POSITION;\n\tfloat NEAR_PLANE;\n\tvec3 DIRECTION;\n" &
      "\tfloat FAR_PLANE;\n\tfloat ASPECT;\n"
  res.add "};\n"

proc prelude(version: string, cameraImpl: NimNode): string =
  result.add "#version " & version & "\n"
  result.add "precision highp float;\n"
  result.add "precision highp int;\n"
  if version.endsWith("es"):
    result.add "precision highp sampler2DArray;\n" &
      "precision highp sampler2DArrayShadow;\n"
  result.add "\n"
  result.add "struct CameraGLSL {\n"
  emitCameraStruct(result, cameraImpl)
  result.add "uniform CameraGLSL GLSL_CAMERA;\n\n"

proc layoutInline(fn: GlslFn): ShaderLayout =
  ## ShaderLayout metadata from the captured layout/batch params.
  for p in fn.params:
    if p.io in {piLayoutIn, piLayoutOut}:
      let t = p.glslType
      let rows = t.rows
      let columns = t.columns
      let size = t.sizeBytes
      result.attrs.add ShaderAttribute(
        typeName: p.attrTypeName,
        index: p.location,
        size: size,
        instanced: p.instanced,
        rows: rows,
        columns: columns,
        columnSize: (if rows > 0: size div rows else: size),
      )

proc toGLSLInner(s, cameraImpl: NimNode,
                scopeFiles: seq[string]): (string, ShaderLayout) =
  let (unit, cap) = captureUnit(s, scopeFiles)
  discard cap
  var code = if OPENGL_SHADER_VERSION == "300 es":
    prelude("300 es", cameraImpl)
  elif OPENGL_SHADER_VERSION == "410":
    prelude("410", cameraImpl)
  else:
    prelude($OPENGL_SHADER_VERSION, cameraImpl)
  emitUnitBody(code, unit)
  emitMain(code, unit)
  result = (code, unit.fn.layoutInline)

macro toGLSL*(s: typed, scope: static[seq[string]] = @[],
              ): (string, ShaderLayout) =
  ## Converts a shader proc into (glslSource, ShaderLayout).
  ##
  ## `scope` lists additional file base names (e.g. @["helpers.nim"])
  ## whose helper procs may be compiled into the shader.
  let impl = s.getImpl()
  let camImpl = bindSym("CameraGLSL").getImpl()
  result = newLit(toGLSLInner(impl, camImpl, scope))

func `stride`*(layout: ShaderLayout): int =
  for data in layout.attrs:
    result += data.size

func `count`*(layout: ShaderLayout): int = layout.attrs.len
func `instanced`*(layout: ShaderLayout): bool =
  for data in layout.attrs:
    if data.instanced:
      return true
  false
