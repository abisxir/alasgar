# https://github.com/treeform/shady
## Shader macro, converts Nim code into GLSL

import macros, strutils, tables, vmath, strformat, osproc
import ../utils

export vmath, utils

var useResult {.compiletime.}: bool

proc listSamplers(): array[51, string] =
  [
    "samplerBuffer", 
    "sampler1D", 
    "sampler1DArray", 
    "sampler2D", 
    "sampler2DArray", 
    "sampler2DRect", 
    "sampler3D", 
    "samplerCube", 
    "samplerCubeArray", 
    "sampler1DShadow", 
    "sampler1DArrayShadow", 
    "sampler2DShadow", 
    "sampler2DArrayShadow", 
    "sampler2DRectShadow", 
    "samplerCubeShadow", 
    "samplerCubeArrayShadow", 
    "imageBuffer",
    "isamplerBuffer", 
    "isampler1D", 
    "isampler1DArray", 
    "isampler2D", 
    "isampler2DArray", 
    "isampler2DRect", 
    "isampler3D", 
    "isamplerCube", 
    "isamplerCubeArray", 
    "isampler1DShadow", 
    "isampler1DArrayShadow", 
    "isampler2DShadow", 
    "isampler2DArrayShadow", 
    "isampler2DRectShadow", 
    "isamplerCubeShadow", 
    "isamplerCubeArrayShadow", 
    "iimageBuffer",
    "usamplerBuffer", 
    "usampler1D", 
    "usampler1DArray", 
    "usampler2D", 
    "usampler2DArray", 
    "usampler2DRect", 
    "usampler3D", 
    "usamplerCube", 
    "usamplerCubeArray", 
    "usampler1DShadow", 
    "usampler1DArrayShadow", 
    "usampler2DShadow", 
    "usampler2DArrayShadow", 
    "usampler2DRectShadow", 
    "usamplerCubeShadow", 
    "usamplerCubeArrayShadow", 
    "uimageBuffer",
  ]

proc listInternalTypes(): seq[string] = 
  let 
    samplers = listSamplers()
    structs: array[4, string] = [
      "Layout",
      "Uniform",
      "UniformWriteOnly",
      "Attribute",
    ] 
  add(result, samplers)
  add(result, structs)

proc isInternalType(t: string): bool =
  for token in listInternalTypes():
    if toLower(token) in toLower(t):
      return true

proc isSampler(sampler: string): bool =
  let l = toLower(sampler)
  for token in listSamplers():
    if toLower(token) in l:
      return true

proc getSampler(sampler: string): string =
  let l = toLower(sampler)
  for token in listSamplers():
    if toLower(token) in l:
      return token

proc isLogicalOp(n: NimNode): bool = n[0].repr in ["and", "or", "xor", "shr", "shl"]
proc getLogicalOp(n: NimNode): string = 
  case n[0].repr:
    of "and": "&&"
    of "or": "||"
    of "not": "!"
    else: n[0].repr
proc isBitwiseOp(n: NimNode): bool = n[0].repr in ["and", "or", "xor", "shr", "shl"] and n[1].getType().repr in ["int", "uint"]
proc getBitwiseOp(n: NimNode): string = 
  case n[0].repr:
    of "and": "&"
    of "or": "|"
    of "xor": "^"
    of "shr": ">>"
    of "shl": "<<"
    else: n[0].repr

proc err(msg: string, n: NimNode) {.noreturn.} =
  error(&"[GLSL] {msg}: {n.repr}", n)

proc typeRename(t: string): string =
  ## Some GLSL type names don't match Nim names, rename here.
  case t
  of "Mat2": "mat2"
  of "Mat3": "mat3"
  of "Mat4": "mat4"

  of "Vec2": "vec2"
  of "Vec3": "vec3"
  of "Vec4": "vec4"

  of "IVec2": "ivec2"
  of "IVec3": "ivec3"
  of "IVec4": "ivec4"

  of "UVec2": "uvec2"
  of "UVec3": "uvec3"
  of "UVec4": "uvec4"

  of "DVec2": "dvec2"
  of "DVec3": "dvec3"
  of "DVec4": "dvec4"

  of "int32": "int"
  of "uint32": "uint"

  of "float32": "float"
  of "float64": "float"
  of "Uniform": "uniform"
  of "UniformWriteOnly": "writeonly uniform"
  of "Attribute": "attribute"
  of "Layout": "layout"
  else: 
    if isSampler(t):
      getSampler(t)
    else:
      t

proc parseLayoutType(n: NimNode): string =
  echo $n
  let 
    binding = "location"
    place = 0
    t = "int"
  result = &"layout({binding}={place}) {t}"

proc typeString(n: NimNode): string =
  if n.kind != nnkBracketExpr:
    typeRename(n.strVal)
  else:
    case n.repr:
    of "GMat2[float32]": "mat2"
    of "GMat3[float32]": "mat3"
    of "GMat4[float32]": "mat4"
    of "GVec2[float32]": "vec2"
    of "GVec3[float32]": "vec3"
    of "GVec4[float32]": "vec4"
    of "GMat2[float64]": "dmat2"
    of "GMat3[float64]": "dmat3"
    of "GMat4[float64]": "dmat4"
    of "GVec2[float64]": "dvec2"
    of "GVec3[float64]": "dvec3"
    of "GVec4[float64]": "dvec4"
    of "GVec2[uint32]": "uvec2"
    of "GVec3[uint32]": "uvec3"
    of "GVec4[uint32]": "uvec4"
    of "GVec2[int32]": "ivec2"
    of "GVec3[int32]": "ivec3"
    of "GVec4[int32]": "ivec4"
    #of "GMat2[T]": "mat2"
    #of "GMat3[T]": "mat3"
    #of "GMat4[T]": "mat4"
    #of "GVec2[T]": "vec2"
    #of "GVec3[T]": "vec3"
    #of "GVec4[T]": "vec4"
    of "Uniform[float]": "float"
    of "Uniform[float64]": "float"
    of "Uniform[float32]": "float"
    of "Uniform[int]": "int"
    of "Uniform[int64]": "int"
    of "Uniform[int32]": "int"
    else:
      if startsWith(n.repr, "Layout"):
        parseLayoutType(n)
      else:
        echo n.repr
        err "can't figure out type", n

## Default constructor for different GLSL types.
proc typeDefault(t: string, n: NimNode): string =
  case t
  of "mat2": "mat2(0.0)"
  of "mat3": "mat3(0.0)"
  of "mat4": "mat4(0.0)"
  of "vec4": "vec4(0.0)"
  of "vec3": "vec3(0.0)"
  of "vec2": "vec2(0.0)"

  of "uvec2": "uvec2(0)"
  of "uvec3": "uvec3(0)"
  of "uvec4": "uvec4(0)"
  of "ivec2": "ivec2(0)"
  of "ivec3": "ivec3(0)"
  of "ivec4": "ivec4(0)"

  of "float": "0.0"
  of "int": "0"
  else:
    err "no typeDefault " & t, n

const glslGlobals = [
  "gl_Position", 
  "gl_FragCoord", 
  "gl_GlobalInvocationID", 
  "gl_VertexID", 
  "gl_FrontFacing"
]

## List of function that GLSL provides, don't include their Nim src.
const glslFunctions = [
  "bool", "array",
  "vec2", "vec3", "vec4", "mat2", "mat3", "mat4",
  "Vec2", "Vec3", "Vec4", "mat2", "Mat3", "Mat4",
  "uvec2", "uvec3", "uvec4",
  "UVec2", "UVec3", "UVec4",
  "ivec2", "ivec3", "ivec4",
  "IVec2", "IVec3", "IVec4",

  "abs", "clamp", "min", "max", "dot", "sqrt", "mix", "length", "cross", "reflect",
  "smoothstep",
  "dFdx", "dFdy", 
  "texelFetch", "imageStore", "imageLoad", "texture", "textureLod",
  "normalize",
  "floor", "ceil", "round", "exp", "inversesqrt", "exp2",
  "[]", "[]=",
  "inverse",
  "sin", "cos", "tan", "pow",
  "lessThan", "lessThanEqual", "greaterThan", "greaterThanEqual",
  "equal", "notEqual",
  "unpackUnorm4x8", "unpackUnorm2x16",
]

## Simply SKIP these functions.
const ignoreFunctions = [
  "echo", "print", "debugEcho", "$"
]

proc isVectorAccess(s: string): bool =
  ## is it a x,y,z or swizzle rgba=
  for flavor in ["xyzw", "rgba", "stpq"]:
    if s[0] in flavor:
      for i, c in s:
        if c notin flavor:
          if c == '=' and i == s.len - 1:
            return true
          else:
            return false
      return true
  return  false

proc procRename(t: string): string =
  ## Some GLSL proc names don't match Nim names, rename here.
  case t
  of "not": "!"
  of "and": "&&"
  of "or": "||"
  of "mod": "%"
  else: t.replace("`", "_")

proc opPrecedence(op: string): int =
  ## Given an operator return its precedence.
  ## Used to decide if () are needed.
  ## See: https://learnwebgl.brown37.net/12_shader_language/glsl_mathematical_operations.html
  case op:
  of "*", "/": 4
  of "+", "-": 5
  of "shr", "shl": 6
  of "<", ">", "<=", ">=": 7
  of "==", "!=": 8
  of "&&": 12
  of "^^": 13
  of "||": 14
  of "=", "+=", "-=", "*=", "/=": 16
  else: -1

proc getPrecedence(n: NimNode): int =
  ## Return the opPrecedence of the node operator or -1.
  if n.kind == nnkInfix:
    n[0].strVal.opPrecedence()
  else:
    -1

proc addIndent(res: var string, level: int) =
  ## Add indent (only if its needed).
  var
    idx = res.len - 1
    spaces = 0
  while res[idx] == ' ':
    dec idx
    inc spaces
  if spaces == 0 and res[idx] != '\n':
    res.add '\n'
  let level = level - spaces div 2
  for i in 0 ..< level:
    res.add "  "

proc addSmart(res: var string, c: char, others = {'}'}) =
  ## Ads a char but first checks if its already here.
  var idx = res.len - 1
  while res[idx] in Whitespace:
    dec idx
  if res[idx] != c and res[idx] notin others:
    res.add c

proc toCodeStmts(n: NimNode, res: var string, level = 0)

proc toCode(n: NimNode, res: var string, level = 0) =
  ## Inner code block.

  case n.kind

  of nnkAsgn:
    res.addIndent level
    n[0].toCode(res)
    res.add " = "
    n[1].toCode(res)
    res.addSmart ';'

  of nnkInfix:
    if n[0].repr in ["mod"] and n[1].getType().repr notin ["int", "uint"]:
      # In Nim float mod and integer made are same thing.
      # In GLSL mod(float, float) is a function while % is for integers.
      res.add n[0].repr
      res.add "("
      n[1].toCode(res)
      res.add ", "
      n[2].toCode(res)
      res.add ")"
    elif n[0].repr == "mod":
      n[1].toCode(res)
      res.add " % "
      n[2].toCode(res)
      res.addSmart ';'
    elif n[0].repr == "div":
      n[1].toCode(res)
      res.add " / "
      n[2].toCode(res)
      res.addSmart ';'
    elif n[0].repr in ["+=", "-=", "*=", "/="]:
      res.addIndent level
      n[1].toCode(res)
      res.add " "
      n[0].toCode(res)
      res.add " "
      n[2].toCode(res)
      res.addSmart ';'
    elif isBitwiseOp(n):
      n[1].toCode(res)
      res.add " "
      res.add getBitwiseOp(n)
      res.add " "
      n[2].toCode(res)
    elif isLogicalOp(n):
      n[1].toCode(res)
      res.add " "
      res.add getLogicalOp(n)
      res.add " "
      n[2].toCode(res)
    else:
      let
        a = n.getPrecedence()
        l = n[1].getPrecedence()
        r = n[2].getPrecedence()
      if l >= a:
        res.add "("
        n[1].toCode(res)
        res.add ")"
      else:
        n[1].toCode(res)
      res.add " "
      n[0].toCode(res)
      res.add " "
      if r >= a:
        res.add "("
        n[2].toCode(res)
        res.add ")"
      else:
        n[2].toCode(res)

  of nnkHiddenDeref, nnkHiddenAddr:
    n[0].toCode(res)

  of nnkCall, nnkCommand:
    var procName = procRename(n[0].strVal)
    if procName in ignoreFunctions:
      return
    if procName == "[]=":
      n[1].toCode(res)
      for i in 2 ..< n.len - 1:
        res.add "["
        n[i].toCode(res)
        res.add "]"
      res.add " = "
      n[n.len - 1].toCode(res)
      res.addSmart ';'

    elif procName == "[]":
      n[1].toCode(res)
      for i in 2 ..< n.len:
        res.add "["
        n[i].toCode(res)
        res.add "]"

    elif isVectorAccess(procName):
      if n[1].kind == nnkSym:
        n[1].toCode(res)
      else:
        res.add "("
        n[1].toCode(res)
        res.add ")"
      res.add "."
      res.add procName.replace("=", " = ")
      if n.len == 3:
        n[2].toCode(res)
    else:
      res.add procName
      res.add "("
      for j in 1 ..< n.len:
        if j != 1: res.add ", "
        n[j].toCode(res)
      res.add ")"

  of nnkDotExpr:
    n[0].toCode(res)
    res.add "."
    n[1].toCode(res)

  of nnkBracketExpr:
    if n[0].len == 2 and n[0][1].repr == "arr":
      # Fastest vmath translates `obj.x` to `obj.arr[x]` for speed.
      # Translate expanded the `obj.arr[x]` back to `.x` for shader.
      let field = case n[1].repr:
        of "0": ".x"
        of "1": ".y"
        of "2": ".z"
        of "3": ".w"
        else: "[" & n[1].repr & "]"
      n[0][0].toCode(res)
      res.add field
    else:
      n[0].toCode(res)
      res.add "["
      n[1].toCode(res)
      res.add "]"

  of nnkIdent, nnkSym:
    if n.strVal notin ["and", "or", "xor"]:
      res.add procRename(n.strVal)

  of nnkStmtListExpr:
    for j in 0 ..< n.len:
      n[j].toCode(res, level)

  of nnkStmtList:
    for j in 0 ..< n.len:
      if n[j].kind in [nnkCall]:
        res.addIndent level
      n[j].toCode(res, level)
      if n[j].kind notin [nnkLetSection, nnkVarSection, nnkCommentStmt]:
        res.addSmart ';'
        res.add "\n"

  of nnkIfStmt:
    res.addIndent level
    res.add "if ("
    n[0][0].toCode(res)
    res.add ") {\n"
    n[0][1].toCodeStmts(res, level + 1)
    res.addIndent level
    res.add "}"
    var i = 1
    while n.len > i:
      if n[i].kind == nnkElse:
        res.add " else {\n"
        n[i][0].toCodeStmts(res, level + 1)
        res.addIndent level
        res.add "}"
      elif n[i].kind == nnkElifBranch:
        res.add " else if ("
        n[i][0].toCode(res)
        res.add ") {\n"
        n[i][1].toCodeStmts(res, level + 1)
        res.addIndent level
        res.add "}"
      else:
        err "Not supported if branch", n
      inc i

  # of nnkIfExpr:
  #   res.add "("
  #   n[0][0].toCode(res)
  #   res.add ") ? ("
  #   n[1][0].toCode(res)
  #   res.add ") : ("
  #   n[2][0].toCode(res)
  #   res.add ")"

  of nnkConv:
    res.add typeRename(n[0].strVal)
    res.add "("
    n[1].toCode(res)
    res.add ")"

  of nnkHiddenStdConv:
    var typeStr = typeRename(n.getType.repr)
    if typeStr.startsWith("range["):
      n[1].toCode(res)
    elif typeStr == "float" and n[1].kind == nnkIntLit:
      res.add $n[1].intVal.float64
    elif typeStr == "float" and n[1].kind == nnkFloatLit:
      res.add $n[1].floatVal.float64
    else:
      for j in 1 .. n.len-1:
        res.add typeStr
        res.add "("
        n[j].toCode(res)
        res.add ")"

  of nnkNone:
    assert false

  of nnkEmpty, nnkNilLit, nnkDiscardStmt, nnkPragma:
    # Skip all nil, empty and discard statements.
    discard

  of nnkIntLit .. nnkInt64Lit:
    var iv = $n.intVal
    res.add iv

  of nnkFloatLit .. nnkFloat64Lit:
    var fv = $n.floatVal
    res.add fv

  of nnkStrLit .. nnkTripleStrLit:
    res.add $n.strVal.newLit.repr

  of nnkCommentStmt:
    # preserve comments
    for line in n.strVal.split("\n"):
      res.addIndent level
      res.add "// "
      res.add line
      res.add "\n"

  of nnkVarSection, nnkLetSection:
    ## var and let ares the same in GLSL
    for j in 0 ..< n.len:
      res.addIndent level
      n[j].toCode(res, level)
      res.addSmart ';'
      res.add "\n"

  of nnkIdentDefs:
    for j in countup(0, n.len - 1, 3):
      var typeStr = ""
      if n[1].kind == nnkBracketExpr and
        n[1][0].kind == nnkSym and
        n[1][0].strVal == "array":
        typeStr = typeRename(n[1][2].strVal)
        typeStr.add "["
        typeStr.add n[1][1].repr
        typeStr.add "]"

        res.add typeStr
        res.add " "
        n[0].toCode(res)
      else:
        typeStr = typeString(n[j].getTypeInst())
        res.add typeStr
        res.add " "
        n[j].toCode(res)
        if n[j + 2].kind != nnkEmpty:
          res.add " = "
          n[j + 2].toCode(res)
        else:
          res.add " = "
          res.add typeDefault(typeStr, n[j])

  of nnkReturnStmt:
    res.addIndent level
    if n[0].kind == nnkAsgn:
      n[0].toCode(res)
      res.add "\n"
      res.addIndent level
      res.add "return result"
    elif n[0].kind != nnkEmpty:
      res.add "return "
      n[0][1].toCode(res)
    elif useResult:
      res.add "return result"
    else:
      res.add "return"

  of nnkPrefix:
    res.add procRename(n[0].strVal) & " ("
    n[1].toCode(res)
    res.add ")"

  of nnkWhileStmt:
    res.addIndent level
    res.add "while("
    n[0].toCode(res)
    res.add ") {\n"
    n[1].toCode(res, level + 1)
    res.addIndent level
    res.add "}"

  of nnkForStmt:
    res.addIndent level
    res.add "for("
    res.add "int "
    res.add n[0].strVal
    res.add " = "
    n[1][1].toCode(res)
    res.add "; "
    res.add n[0].strVal
    if n[1][0].strVal == "..<":
      res.add " < "
    elif n[1][0].strVal == "..":
      res.add " <= "
    else:
      err "For loop only supports integer .. or ..<.", n
    n[1][2].toCode(res)
    res.add "; "
    res.add n[0].strVal
    res.add "++"
    res.add ") {\n"
    if n[2].kind == nnkStmtList:
      n[2].toCode(res, level + 1)
    else:
      res.addIndent level
      n[2].toCode(res, level + 1)
      res.add ";"
    res.addIndent level
    res.add "}"

  of nnkBreakStmt:
    res.addIndent level
    res.add "break"

  of nnkProcDef:
    err "Nested proc definitions are not allowed.", n

  of nnkCaseStmt:
    res.addIndent level
    res.add "switch("
    n[0].toCode(res)
    res.add ") {\n"
    for branch in n[1 .. ^1]:
      if branch.kind == nnkOfBranch:
        res.addIndent level
        res.add "case "
        branch[0].toCode(res)
        res.add ":{\n"
        branch[1].toCodeStmts(res, level + 1)
        res.addIndent level
        if branch[1].kind == nnkReturnStmt or branch[1].kind == nnkBreakStmt:
          res.add "};\n"
        else:
          res.add "}; break;\n"
      elif branch.kind == nnkElse:
        res.addIndent level
        res.add "default: {\n"
        branch[0].toCodeStmts(res, level + 1)
        res.addIndent level
        if branch[0].kind == nnkReturnStmt or branch[0].kind == nnkBreakStmt:
          res.add "};\n"
        else:
          res.add "}; break;\n"
      else:
        err "Can't compile branch", n
    res.addIndent level
    res.add "}"

  of nnkChckRange:
    # skip check range and treat it as a hidden cast instead
    var typeStr = typeRename(n.getType.repr)
    res.add typeStr
    res.add "("
    n[0].toCode(res)
    res.add ")"

  of nnkObjConstr:
    if repr(n[0][0]) == "[]":
      # probably a swizzle call.
      res.add n[1][1][1][1][0][0].strval
      res.add "."
      for part in n[1][1]:
        res.add "xyzw"[part[1][1][1].intVal]
    else:
      echo n.treeRepr
      err "Some sort of object constructor", n

  of nnkIfExpr:
    var gotElse = false
    res.add "("
    for subn in n:
      case subn.kind
      of nnkElifExpr:
        if gotElse:
          echo n.treeRepr
          err "Cannot have elif after else", n
        res.add "("
        subn[0].toCode(res)
        res.add ") ? ("
        subn[1].toCode(res)
        res.add ") : "
      of nnkElseExpr:
        gotElse = true
        res.add "("
        subn[0].toCode(res)
        res.add ")"
      else:
        echo n.treeRepr
        err "Invalid child of nnkIfExpr: " & subn.kind.repr, n
    res.add ")"
    if not gotElse:
      echo n.treeRepr
      err "nnkIfExpr is missing an else clause", n
  else:
    echo n.treeRepr
    err "Can't compile", n

proc toCodeStmts(n: NimNode, res: var string, level = 0) =
  if n.kind != nnkStmtList:
    res.addIndent level
    n.toCode(res, level)
    res.addSmart ';'
    res.add "\n"
  else:
    n.toCode(res, level)

proc parseBracket(param: NimNode, res: var string, forceOut=false): int =
  let 
    prefix = typeRename(param[0].strVal)
  res.add(prefix)
  if prefix == "layout":
    if isSampler(param[2].repr):
      res.add(&"(binding={param[1].intVal}) ")
    else:
      res.add(&"(location={param[1].intVal}) ")
      if param.kind == nnkVarTy or forceOut:
        res.add("out ")
      else:
        res.add("in ")
    if param[2].kind == nnkBracketExpr:
      return parseBracket(param[2], res)
    else:
      res.add(typeRename(param[2].strVal))
  elif len(param[1]) > 0 and param[1][0].repr == "array":
    let arr = param[1]
    res.add &" {typeRename(arr[2].repr)}"
    return arr[1].intVal.int;
  else:
    res.add " "
    res.add typeRename(param[1].strVal)

proc toCodeTopLevel(topLevelNode: NimNode, res: var string, level = 0) =
  ## Top level block such as in and out params.
  ## Generates the main function (which is not like all the other functions)

  assert topLevelNode.kind == nnkProcDef

  for n in topLevelNode:
    case n.kind
    of nnkEmpty:
      discard
    of nnkSym:
      discard
    of nnkFormalParams:
      ## Main function parameters are different in they they go in as globals.
      for param in n:
        if param.kind != nnkEmpty:
          if param[0].strVal in glslGlobals:
            continue
          var arraySize = -1
          if param[1].kind == nnkVarTy:
            #if param[0].strVal == "fragColor":
            #  res.add "layout(location = 0) "
            if param[1][0].repr == "seq":
              res.add "buffer?"
              res.add param[1].repr
              continue
            #elif param[1][0].repr == "int":
            #  res.add "flat "
            if param[1][0].kind == nnkBracketExpr:
              arraySize = parseBracket(param[1][0], res, true)
            else:
              res.add "out "
              res.add typeRename(param[1][0].strVal)
          else:
            if param[1].kind == nnkBracketExpr:
              arraySize = parseBracket(param[1], res)
            else:
              if param[0].strVal == "gl_FragCoord":
                res.add "layout(origin_upper_left) "
              #if param[1].strVal == "int":
              #  res.add "flat "
              res.add "in "
              res.add typeRename(param[1].strVal)
          res.add " "
          if arraySize > 0:
            res.add &"{param[0].strVal}[{arraySize}]"
          else:
            res.add param[0].strVal
          res.addSmart ';'
          res.add "\n"
    else:
      res.add "\n"
      res.add "void main() {\n"
      n.toCodeStmts(res, level+1)
      res.add "}\n"

proc hasResult(node: NimNode): bool =
  if node.kind == nnkSym and node.strVal == "result":
    return true
  for c in node.children:
    if c.hasResult():
      return true
  return false

proc procDef(topLevelNode: NimNode): string =
  ## Process whole function (that is not the main function).

  var procName = ""
  var paramsStr = ""
  var returnType = "void"

  assert topLevelNode.kind in {nnkFuncDef, nnkProcDef}
  echo "* ", topLevelNode.repr
  for n in topLevelNode:
    case n.kind
    of nnkEmpty, nnkPragma:
      discard
    of nnkSym:
      procName = $n
    of nnkFormalParams:
      # Reading parameter list `(x, y, z: float)`
      if n[0].kind != nnkEmpty:
        returnType = typeString(n[0])
      for paramDef in n[1 .. ^1]:
        # The paramDef is like `x, y, z: float`.
        if paramDef.kind != nnkEmpty:
          for param in paramDef[0 ..< ^2]:
            # Process each `x`, `y`, `z` in a loop.
            paramsStr.add "  "
            let paramName = param.repr()
            let paramType = param.getTypeInst()
            if paramType.kind == nnkVarTy:
              # Process `x: var float`
              #if paramType[0].strVal == "int":
              #  paramsStr.add "flat "
              paramsStr.add "inout "
              paramsStr.add typeRename(paramType[0].strVal)
            elif paramType.kind == nnkBracketExpr:
              # Process varying[uniform].
              # TODO test?
              paramsStr.add paramType[0].strVal
              paramsStr.add " "
              paramsStr.add typeRename(paramType[1].strVal)
            else:
              # Just a simple `x: float` case.
              #if paramType.strVal == "int":
              #  paramsStr.add "flat "
              paramsStr.add typeRename(paramType.strVal)
            paramsStr.add " "
            paramsStr.add paramName
            paramsStr.add ",\n"
    else:
      result.add "\n"
      if paramsStr.len > 0:
        paramsStr = paramsStr[0 .. ^3] & "\n"
      result.add returnType & " " & procName & "(\n" & paramsStr & ") {\n"
      useResult = n.hasResult()
      if useResult:
        result.addIndent(1)
        result.add returnType
        result.add " result;"
      n.toCodeStmts(result, 1)
      if useResult:
        if "return result" notin result[^20..^1]:
          result.addIndent(1)
          result.add "return result;\n"
      result.add "}"

proc getDeclartion(n: NimNode): string =
  let 
    typeInst = n.getTypeInst()
    impl = n.getImpl()
  ## Get the declaration of a function.
  if impl.kind == nnkTypeDef:
    result = "struct"
  elif typeInst.kind == nnkBracketExpr:
    # might be a uniform
    if typeInst[0].repr in ["Uniform", "UniformWriteOnly", "Attribute", "typeDesc"]:
      result = &"{typeRename(typeInst[0].repr)} {typeRename(typeInst[1].repr)}"
    elif typeInst[0].repr == "array":
      result = &"{typeRename(typeInst[2].repr)}[{typeRename(typeInst[1][2].repr)}]"
    else:
      err &"Invalid x[y]: {typeInst[0].repr}", n
  else:
    result = typeRename(typeInst.repr)
  
  result = result & " "
  

proc gatherFunction(
  topLevelNode: NimNode,
  functions: var Table[string, string],
  globals: var Table[string, string]
) =
  ## Looks for functions this function calls and brings them up
  for n in topLevelNode:
    echo &" - {n.repr} started."
    if n.kind == nnkSym:
      # Looking for globals.
      let name = n.strVal
      if name notin glslGlobals and name notin glslFunctions and name notin globals:
        if n.owner().symKind == nskModule:
          let impl = n.getImpl()
          if impl.kind notin {nnkIteratorDef, nnkProcDef, nnkFuncDef} and
              impl.kind != nnkNilLit and
              (impl.kind != nnkTypeDef or not isInternalType(impl[0].repr)) :
            var defStr = getDeclartion(n)
            if impl.kind == nnkTypeDef:
              defStr.add " { \n"
              for item in impl[2]:
                if item.kind == nnkRecList:
                  for prop in item:
                    if prop.kind == nnkIdentDefs:
                      if prop[0].kind == nnkPostfix:
                        defStr.add &"  {typeRename(prop[1].repr)} {prop[0][1]};\n"
                      else:
                        defStr.add &"  {typeRename(prop[1].repr)} {prop[0]};\n"
              defStr.add "};\n"
            elif impl[2].kind != nnkEmpty:
              defStr.add " = " & repr(impl[2])
            defStr.addSmart ';'
            if defStr notin ["uniform Uniform = T;",
                "attribute Attribute = T;"]:
              globals[name] = defStr

    if n.kind == nnkCall:
      # Looking for functions.
      if repr(n[0]) == "[]":
        continue
      let procName = repr n[0]
      if procName in ignoreFunctions:
        continue
      if procName notin glslFunctions and
        procName notin functions and
        not isVectorAccess(procName):
        ## If its not a builtin proc, we need to bring definition.
        let impl = n[0].getImpl()
        gatherFunction(impl, functions, globals)
        functions[procName] = procDef(impl)

    gatherFunction(n, functions, globals)
    echo &" + {n.repr} ended."

proc toGLSLInner*(s: NimNode, version, extra: string): string =

  var code: string

  # Add GLS header stuff.
  code.add "// from " & s.strVal & "\n\n"
  code.add "#version " & version & "\n"
  code.add extra

  var n = getImpl(s)

  # Gather all globals and functions, and globals and functions they use.
  echo "Gather function started..."
  var functions: Table[string, string]
  var globals: Table[string, string]
  gatherFunction(n, functions, globals)
  echo "* Gather function end"

  # Put globals first.
  for k, v in globals:
    code.add(v)
    code.add "\n"

  # Put functions definition (just name and types part).
  if len(functions) > 0:
    code.add "/* Forward declarations */\n"
    for k, v in functions:
      var funCode = v.split(" {")[0]
      funCode = funCode
        .replace("\n", "")
        .replace("  ", " ")
        .replace(",  ", ", ")
        .replace("( ", "(")
      code.add funCode
      code.addSmart ';'
      code.add "\n"

  # Put functions (with bodies) next.
  for k, v in functions:
    code.add v
    code.add "\n"

  code.add "\n"

  # Put the main function last.
  toCodeTopLevel(n, code)

  return code

macro toGLSL*(
  s: typed,
  version = when defined(macosx): "410" else: "310 es",
  extra = "precision highp float;\nprecision highp int;\n"
): string =
  ## Converts proc to a glsl string.
  result = newLit(toGLSLInner(s, version.strVal, extra.strVal))
  #echo(result)

## GLSL helper functions

type
  Layout*[N, T] = T
  Uniform*[T] = T
  UniformWriteOnly*[T] = T
  Attribute*[T] = T
  SamplerBuffer* = object
  Sampler1D* = object
  Sampler1DArray* = object
  Sampler2D* = object
  Sampler2DArray* = object
  Sampler2DRect* = object
  Sampler3D* = object
  SamplerCube* = object
  SamplerCubeArray* = object
  Sampler1DShadow* = object
  Sampler1DArrayShadow* = object
  Sampler2DShadow* = object
  Sampler2DArrayShadow* = object
  Sampler2DRectShadow* = object
  SamplerCubeShadow* = object
  SamplerCubeArrayShadow* = object
  ImageBuffer* = object
  ISamplerBuffer* = object
  ISampler1D* = object
  ISampler1DArray* = object
  ISampler2D* = object
  ISampler2DArray* = object
  ISampler2DRect* = object
  ISampler3D* = object
  ISamplerCube* = object
  ISamplerCubeArray* = object
  ISampler1DShadow* = object
  ISampler1DArrayShadow* = object
  ISampler2DShadow* = object
  ISampler2DArrayShadow* = object
  ISampler2DRectShadow* = object
  ISamplerCubeShadow* = object
  ISamplerCubeArrayShadow* = object
  IImageBuffer* = object
  USamplerBuffer* = object
  USampler1D* = object
  USampler1DArray* = object
  USampler2D* = object
  USampler2DArray* = object
  USampler2DRect* = object
  USampler3D* = object
  USamplerCube* = object
  USamplerCubeArray* = object
  USampler1DShadow* = object
  USampler1DArrayShadow* = object
  USampler2DShadow* = object
  USampler2DArrayShadow* = object
  USampler2DRectShadow* = object
  USamplerCubeShadow* = object
  USamplerCubeArrayShadow* = object
  UImageBuffer* = object


proc texelFetch*(sampler: Sampler2D, P: IVec2, lod: int): Vec4 = discard
proc textureLod*(sampler: SamplerCube, P: Vec3, lod: float): Vec4 = discard
proc texture*(sampler: Sampler2D, P: Vec2): Vec4 = discard
proc ivec2*(x, y: int): IVec2 = discard
proc `-`*(a: float, b: Vec3): Vec3 = discard
proc `*`*(x: Mat4, y: float32): Mat4 = discard
proc `+`*(x: Mat4, y: Mat4): Mat4 = discard
proc exp2*(v: float): float = discard
proc dFdx*(v: Vec3): Vec3 = discard
proc dFdy*(v: Vec3): Vec3 = discard
proc dFdx*(v: Vec2): Vec2 = discard
proc dFdy*(v: Vec2): Vec2 = discard
proc dFdx*(v: float): float = discard
proc dFdy*(v: float): float = discard
proc smoothstep*(a: float, b: float, v: float): float = discard
proc reflect*(a, b: Vec3): Vec3 = discard
proc max*(v: Vec3, f: float): Vec3 = discard