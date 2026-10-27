## Structural mapping from Nim type nodes to GLSL types.
##
## Resolution is driven by type *structure* (generic name + element type),
## never by full `repr` strings, so renames of the algebra types do not
## silently break translation.

import macros
import std/strutils

import builtins

type
  TypeShape* = enum
    tsUnknown, tsScalar, tsVector, tsMatrix, tsSampler

  GlslTypeInfo* = object
    glslName*: string        ## GLSL name without array brackets, e.g. "vec4".
    shape*: TypeShape
    rows*: int               ## matrix rows; 1 for vectors/scalars.
    columns*: int            ## matrix columns; vector dim; 1 for scalars.
    elemBytes*: int          ## bytes of one scalar component.
    arraySize*: int          ## 0 = not an array; >0 = element count.
    sizeBytes*: int          ## rows * columns * elemBytes.

proc errorNoNode(msg: string) {.noreturn.} =
  error("[GLSL] " & msg)

proc dimOf(name: string, prefix: string): int =
  if name.startsWith(prefix):
    for c in name[prefix.len .. ^1]:
      if c in {'2' .. '4'}:
        return c.ord - '0'.ord
  result = 0

proc infoScalar(glslName: string): GlslTypeInfo =
  GlslTypeInfo(glslName: glslName, shape: tsScalar, rows: 1,
    columns: 1, elemBytes: 4, sizeBytes: 4)

proc infoVector(glslName: string, dim: int): GlslTypeInfo =
  GlslTypeInfo(glslName: glslName, shape: tsVector, rows: 1,
    columns: dim, elemBytes: 4, sizeBytes: dim * 4)

proc infoMatrix(glslName: string, dim: int): GlslTypeInfo =
  GlslTypeInfo(glslName: glslName, shape: tsMatrix, rows: dim,
    columns: dim, elemBytes: 4, sizeBytes: dim * dim * 4)

proc infoSampler(glslName: string): GlslTypeInfo =
  GlslTypeInfo(glslName: glslName, shape: tsSampler, sizeBytes: 0)

proc unwrap*(n: NimNode): NimNode =
  ## Removes type-parameter wrappers around a type node.
  var r = n
  while true:
    case r.kind
    of nnkVarTy, nnkRefTy, nnkDistinctTy, nnkTypeOfExpr:
      r = r[0]
    of nnkStmtListExpr, nnkPragmaExpr:
      r = r[^1]
    else:
      return r

proc aliasGlslName(name: string): string =
  let r = lookup(aliases, name)
  if r.len == 0:
    errorNoNode("unknown GLSL alias: " & name)
  r

proc aliasShape(name: string): GlslTypeInfo =
  ## Shape from the public alias name (Vec2 ... Mat4), robust against the
  ## underlying generic type being restructured.
  if name == "Quat":
    return infoVector("vec4", 4)
  var dim = name.dimOf("Vec")
  if dim > 0:
    return infoVector(name.aliasGlslName, dim)
  dim = name.dimOf("IVec")
  if dim > 0:
    return infoVector(name.aliasGlslName, dim)
  dim = name.dimOf("UVec")
  if dim > 0:
    return infoVector(name.aliasGlslName, dim)
  dim = name.dimOf("DVec")
  if dim > 0:
    return infoVector(name.aliasGlslName, dim)
  dim = name.dimOf("Mat")
  if dim > 0:
    return infoMatrix(name.aliasGlslName, dim)
  dim = name.dimOf("DMat")
  if dim > 0:
    return infoMatrix(name.aliasGlslName, dim)
  errorNoNode("unknown vector/matrix alias: " & name)

proc glslTypeOf*(t: NimNode, info: var GlslTypeInfo) =
  ## Fills `info` for a type-context node. Unknown types are errors.
  let n = unwrap(t)
  case n.kind
  of nnkSym:
    let name = n.strVal
    let scalar = lookup(scalars, name)
    if scalar.len > 0:
      info = infoScalar(scalar)
      return
    let samp = name.samplerGlsl
    if samp.len > 0:
      info = infoSampler(samp)
      return
    if lookup(aliases, name).len > 0:
      info = aliasShape(name)
      return
    errorNoNode("unknown GLSL type: " & name)
  of nnkBracketExpr:
    let head = n[0].strVal
    if head == "array":
      if n.len >= 3:
        glslTypeOf(n[2], info)
        if n[1].kind in {nnkIntLit .. nnkInt64Lit}:
          info.arraySize = n[1].intVal.int
        return
      errorNoNode("malformed array type")
    for (base, glslBase, dim, elems) in genVecTypes:
      if head == base:
        if n.len < 2:
          errorNoNode("generic vector is missing its element type: " & head)
        case n[1].strVal.elementKindOf
        of ekInt: info = infoVector("i" & glslBase, dim)
        of ekUint: info = infoVector("u" & glslBase, dim)
        else: info = infoVector(glslBase, dim)
        return
    for (base, glslBase, dim) in genMatTypes:
      if head == base:
        info = infoMatrix(glslBase, dim)
        return
    errorNoNode("unknown generic GLSL type: " & n.repr)
  else:
    errorNoNode("unsupported type node: " & $n.kind & " " & n.repr)

proc glslTypeOf*(t: NimNode): GlslTypeInfo =
  glslTypeOf(t, result)
