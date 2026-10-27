## Symbol scope resolution without the deprecated `owner` API.
##
## Decisions about which symbols are "ours" (module globals, helper procs,
## consts) or foreign (GLSL builtins, engine runtime, other modules) are
## made *structurally*:
##
##  - by name for GLSL builtins (builtins.nim),
##  - by `symKind` for consts/vars/procs,
##  - by definition *file* (lineInfo) for module ownership.
##
## The shader source file plus an optional allowlist (see
## `toGLSL(..., scope = @[...])`) decides which files' helpers may be
## pulled in. Anything else is a compile-time error with a suggestion,
## never a silent skip or a stringly `repr` match.

import macros
import std/[strutils, os]

import builtins

type
  Scope* = object
    ## File names (base names) whose symbols are eligible for compiling
    ## into the shader source.
    allowedFiles*: seq[string]
    ## Symbols bound inside the shader itself (params, locals, for vars).
    boundNames*: seq[string]

proc fileToken*(n: NimNode): string =
  ## `file(12, 5)` -> `file`
  let info = n.lineInfo
  let paren = info.find('(')
  if paren > 0:
    info[0 ..< paren]
  else:
    info

proc baseFile*(n: NimNode): string =
  extractFilename(fileToken(n))

proc lineNumber*(n: NimNode): int =
  let info = n.lineInfo
  let paren = info.find('(')
  let comma = info.rfind(',')
  if paren > 0 and comma > paren:
    try:
      return parseInt(info[paren + 1 ..< comma])
    except ValueError:
      discard
  result = 0

proc newScope*(entry: NimNode, extraFiles: seq[string]): Scope =
  Scope(allowedFiles: @[baseFile(entry)] & extraFiles)

proc isGlobalName*(name: string): bool =
  for g in glslGlobals:
    if g == name:
      return true
  false

const operators* = ["*", "+", "-", "/", "%", "==", "!=", "<", ">",
  "<=", ">=", "and", "or", "xor", "not", "shl", "shr", "&", "|", "^",
  "~", "..", "..<", "+=", "-=", "*=", "/=", "&=", "|=", "^="]

proc isOperator*(name: string): bool =
  for op in operators:
    if op == name:
      return true
  false

proc isBound*(scope: Scope, name: string): bool =
  for b in scope.boundNames:
    if b == name:
      return true
  false

proc isKnownTypeName*(name: string): bool =
  if name.isBuiltinFunc:
    return true
  if lookup(scalars, name).len > 0:
    return true
  if lookup(aliases, name).len > 0:
    return true
  if name.isSamplerType:
    return true
  false

proc isInScopeFile*(scope: Scope, n: NimNode): bool =
  let f = baseFile(n)
  for allowed in scope.allowedFiles:
    if f == allowed:
      return true
  false

proc bindName*(scope: var Scope, name: string) =
  if not scope.isBound(name):
    scope.boundNames.add name

## Resolved definition kinds.
type
  DefKind* = enum
    defBuiltin      ## GLSL builtin or global; no definition needed.
    defLocal        ## local var / let / loop var of the shader.
    defConst        ## module const; value must be emitted.
    defHelper       ## proc/func candidate; body must be emitted.
    defForeign      ## anything else: hard error with hints.

  Def* = object
    kind*: DefKind
    name*: string
    value*: NimNode   ## defConst: the value; defHelper: the impl.
    key*: string      ## stable identity for dedupe (lineInfo).

proc analyze*(scope: Scope, s: NimNode): Def =
  ## Classifies a symbol used in expression/statement position.
  ## `s` is an nnkSym (or nnkIdent) here.
  result.name = s.strVal
  result.kind = defForeign
  result.value = s
  result.key = s.lineInfo

  if s.strVal == "result":
    result.kind = defLocal
    return
  if s.strVal.isGlobalName:
    result.kind = defBuiltin
    return
  if s.strVal.isOperator:
    result.kind = defBuiltin
    return
  if scope.isBound(s.strVal):
    result.kind = defLocal
    return
  if s.strVal.isSwizzle:
    result.kind = defBuiltin
    return
  if s.strVal.isKnownTypeName:
    result.kind = defBuiltin
    return

  case s.symKind
  of nskConst:
    result.kind = defConst
    result.value = s.getImpl()
    result.key = s.lineInfo
  of nskVar, nskLet, nskParam, nskForVar, nskField:
    result.kind = defLocal
    result.value = s.getImpl()
  of nskProc, nskFunc:
    result.kind = defHelper
    result.value = s.getImpl()
    result.key = s.lineInfo
  else:
    result.kind = defForeign
    result.value = s.getImpl()
