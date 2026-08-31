## Captures the typed Nim AST of a shader proc into the GLSL IR.
##
## Every construct that is understood is converted explicitly; anything
## else raises a positioned compile-time error with a suggested fix.
## All symbol decisions go through `scope.nim` (never the deprecated
## `owner` API).

import macros
import std/strutils

import builtins
import ir
import scope
import typeinfo

type
  Capture* = object
    scope*: Scope
    consts*: seq[GlslConst]
    helpers*: seq[GlslFn]
    seen*: seq[string]       ## lineInfo keys of gathered helpers.
    entryInfo*: string       ## lineInfo of the shader proc itself.
    entryName*: string       ## name of the shader proc.

proc glslErr(msg: string, n: NimNode = nil) {.noreturn.} =
  var s = "[GLSL] " & msg
  if n != nil:
    if n.lineInfo != "":
      s.add " at " & n.lineInfo
    s.add " (" & $n.kind & " " & n.repr & ")"
  error(s)

proc unwrapConstInt(n: NimNode): int =
  ## Extracts an integer literal from a (possibly wrapped) node.
  var n = n
  while n.kind in {nnkHiddenStdConv, nnkHiddenSubConv, nnkHiddenDeref}:
    n = n[^1]
  if n.kind in {nnkIntLit .. nnkInt64Lit}:
    n.intVal.int
  else:
    glslErr("loop step must be an integer literal", n)

proc resultUsage(node: NimNode): bool =
  if node.kind == nnkSym and node.strVal == "result":
    return true
  for c in node.children:
    if c.resultUsage():
      return true
  false

# --------------------------------------------------------------- helpers

proc condOf(n: NimNode): NimNode =
  ## Extracts the real condition from condition slots, which Nim 2.x
  ## wraps in an nnkStmtListExpr.
  case n.kind
  of nnkStmtListExpr:
    if n.len == 2 and n[0].kind == nnkEmpty:
      n[1]
    else:
      n[^1]
  else:
    n

proc splitIdentDefs(def: NimNode): tuple[names: seq[NimNode], typ: NimNode,
    default: NimNode] =
  ## Normalizes both single-name and Nim 2.x multi-name IdentDefs shapes:
  ##   (name, type, default)  and  (name, ..., name, type, default).
  if def.len < 2:
    glslErr("cannot split IdentDefs", def)
  var typePos = -1
  for i in 1 ..< def.len:
    let c = def[i]
    if c.kind == nnkSym and not c.strVal.isKnownTypeName:
      continue
    typePos = i
    break
  if typePos == -1:
    glslErr("cannot find a type in IdentDefs", def)
  for i in 0 ..< typePos:
    result.names.add def[i]
  result.typ = def[typePos]
  if typePos + 1 < def.len and def[typePos + 1].kind != nnkEmpty:
    result.default = def[typePos + 1]

proc objConstrFields(obj: NimNode): seq[NimNode] =
  ## Collects field values of an nnkObjConstr in declaration order.
  for i in 1 ..< obj.len:
    let child = obj[i]
    case child.kind
    of nnkExprColonExpr, nnkExprEqExpr:
      result.add child[1]
    of nnkRecList:
      for f in child:
        if f.kind == nnkExprColonExpr:
          result.add f[1]
        elif f.kind == nnkIdentDefs:
          result.add f[^1]
        else:
          result.add f
    else:
      result.add child

# ----------------------------------------------------------- expr pass

proc toExpr(n: NimNode, cap: var Capture): Expr
proc collectConst(cap: var Capture, def: Def): Expr
proc captureFn(impl: NimNode, cap: var Capture, kind: FnKind,
               entryName: string): GlslFn

proc mustBeBuiltinInt(n: NimNode): bool =
  ## True when the expression node's static type is int/uint-ish; used to
  ## decide whether `and`/`or`/`xor` become bitwise or logical operators.
  ## Handles the Layout/Batch/Uniform wrappers around scalar types.
  var t = n.getTypeInst()
  while t.kind in {nnkVarTy, nnkRefTy, nnkTypeOfExpr, nnkHiddenStdConv}:
    t = t[0]
  if t.kind == nnkBracketExpr and t.len >= 2 and t[0].strVal in
      ["Layout", "Batch", "Uniform", "UniformWriteOnly"]:
    t = t[^1]
  result = t.kind == nnkSym and t.strVal in
    ["int", "int32", "int64", "uint", "uint32", "uint64"]

proc callHelper(cap: var Capture, callee, impl: NimNode) =
  ## Gathers a helper proc (recursively) if its file is in scope.
  let key = impl.lineInfo
  if key in cap.seen:
    return
  if not cap.scope.isInScopeFile(impl):
    glslErr("helper '" & callee.strVal & "' is defined in '" &
      baseFile(impl) & "' but not in the shader scope; pass its module " &
      "name to toGLSL(..., scope = @[...]) or move it into one of the " &
      "shader files", callee)
  cap.seen.add key
  let fn = captureFn(impl, cap, fkHelper, callee.strVal)
  cap.helpers.add fn

proc toExpr(n: NimNode, cap: var Capture): Expr =
  case n.kind
  of nnkHiddenDeref, nnkHiddenAddr, nnkHiddenStdConv, nnkHiddenSubConv:
    result = toExpr(n[^1], cap)
  of nnkSym:
    let def = cap.scope.analyze(n)
    case def.kind
    of defLocal:
      result = newVar(def.name, n.lineInfo)
    of defBuiltin:
      if n.strVal.isGlobalName:
        result = newVar(n.strVal, n.lineInfo)
      else:
        glslErr("builtin type used where a value was expected", n)
    of defConst:
      discard collectConst(cap, def)
      result = newVar(def.name, n.lineInfo)
    else:
      glslErr("unresolved symbol in expression; declare it in the shader " &
        "or inject it as Uniform[]/Layout[]", n)
  of nnkIdent:
    result = newVar(n.strVal, n.lineInfo)
  of nnkDotExpr:
    let left = toExpr(n[0], cap)
    let right = n[1]
    case right.kind
    of nnkSym, nnkIdent:
      let fs = right.strVal
      result = newField(left, newVar(fs, n.lineInfo), n.lineInfo)
    else:
      glslErr("unsupported dot target", n)
  of nnkBracketExpr:
    # `obj.arr[i]` re-expansion from the algebra's structural fields.
    if n[0].kind == nnkBracketExpr and n[0].len == 2 and
        n[0][1].kind in {nnkSym, nnkIdent} and n[0][1].strVal == "arr":
      let base = toExpr(n[0][0], cap)
      let idx = n[1]
      if idx.kind in {nnkIntLit .. nnkInt64Lit}:
        let i = idx.intVal.int
        if i in 0 .. 3:
          result = newField(base, newVar($"xyzw"[i], n.lineInfo), n.lineInfo)
          return
      result = newIndex(base, toExpr(idx, cap), n.lineInfo)
      return
    result = newIndex(toExpr(n[0], cap), toExpr(n[1], cap), n.lineInfo)
  of nnkCall:
    let callee = n[0]
    case callee.kind
    of nnkSym, nnkIdent:
      let name = callee.strVal
      if name.isSwizzle:
        if n.len != 2:
          glslErr("swizzle functions take exactly one argument", n)
        let r = newExpr(eSwizzle, n.lineInfo)
        r.name = name
        r.children = @[toExpr(n[1], cap)]
        return r
      if name.isBuiltinFunc:
        var args: seq[Expr]
        for i in 1 ..< n.len:
          args.add toExpr(n[i], cap)
        return newCall(name, args, n.lineInfo)
      let def = cap.scope.analyze(callee)
      if def.kind == defHelper:
        callHelper(cap, callee, def.value)
        var args: seq[Expr]
        for i in 1 ..< n.len:
          args.add toExpr(n[i], cap)
        return newCall(def.name, args, n.lineInfo)
      glslErr("unknown function '" & name & "': not a GLSL builtin and " &
        "not in the shader scope; functions without public names can be " &
        "inlined manually", n)
    of nnkDotExpr:
      let moduleName = callee[0].strVal
      let procName = callee[1].strVal
      let def = cap.scope.analyze(callee[1])
      if def.kind == defHelper:
        callHelper(cap, callee[1], def.value)
        var args: seq[Expr]
        for i in 1 ..< n.len:
          args.add toExpr(n[i], cap)
        return newCall(procName, args, n.lineInfo)
      glslErr("unknown qualified function: " & moduleName & "." &
        procName, n)
    else:
      glslErr("unsupported call target", n)
  of nnkInfix:
    let opName = n[0].strVal
    let left = toExpr(n[1], cap)
    let right = toExpr(n[2], cap)
    let intish = mustBeBuiltinInt(n[1])
    case opName
    of "and":
      return newBinary(if intish: "&" else: "&&", left, right, n.lineInfo)
    of "or":
      return newBinary(if intish: "|" else: "||", left, right, n.lineInfo)
    of "xor":
      return newBinary(if intish: "^" else: "!=", left, right, n.lineInfo)
    of "shl", "<<": return newBinary("<<", left, right, n.lineInfo)
    of "shr", ">>": return newBinary(">>", left, right, n.lineInfo)
    of "mod":
      # GLSL `%` binds integers only; float remainder is mod(a, b).
      if intish:
        return newBinary("%", left, right, n.lineInfo)
      return newCall("mod", @[left, right], n.lineInfo)
    of "div": return newBinary("/", left, right, n.lineInfo)
    of "in":
      glslErr("the 'in' operator cannot be translated to GLSL", n)
    else:
      case opName
      of "+", "-", "*", "/", "%", "==", "!=", "<", ">", "<=", ">=",
          "&&", "||", "^", "&", "|", "<<", ">>":
        return newBinary(opName, left, right, n.lineInfo)
      else:
        glslErr("operator '" & opName & "' has no GLSL equivalent " &
          "(use a builtin function instead)", n)
  of nnkPrefix:
    let p = n[0].strVal
    let arg = toExpr(n[1], cap)
    case p
    of "-": return newPref("-", arg, n.lineInfo)
    of "+": return arg
    of "not": return newPref("!", arg, n.lineInfo)
    of "~": return newPref("~", arg, n.lineInfo)
    else:
      glslErr("unknown prefix operator: " & p, n)
  of nnkConv:
    let typ = glslTypeOf(n[0])
    result = newExpr(eCast, n.lineInfo)
    result.castType = typ.glslName
    result.value = toExpr(n[1], cap)
  of nnkObjConstr:
    var ctorName: string
    if n[0].kind == nnkEmpty:
      ctorName = glslTypeOf(n.getTypeInst()).glslName
    else:
      ctorName = glslTypeOf(n[0]).glslName
    if ctorName.len == 0:
      glslErr("cannot resolve object constructor name", n)
    var args: seq[Expr]
    for f in objConstrFields(n):
      args.add toExpr(f, cap)
    result = newCall(ctorName, args, n.lineInfo)
  of nnkIfExpr:
    let r = newExpr(eTernary, n.lineInfo)
    for branch in n:
      case branch.kind
      of nnkElifExpr:
        r.cond = toExpr(branch[0], cap)
        r.thenExpr = toExpr(branch[1], cap)
      of nnkElseExpr:
        r.elseExpr = toExpr(branch[0], cap)
      else:
        glslErr("invalid if-expression branch", branch)
    if r.elseExpr == nil:
      glslErr("shader if-expressions need a full else branch", n)
    result = r
  of nnkIntLit .. nnkInt64Lit:
    result = newLit($n.intVal, eLitInt)
  of nnkFloatLit .. nnkFloat64Lit:
    var fv = $n.floatVal
    if fv.find('.') < 0 and fv.find('e') < 0:
      fv.add ".0"
    result = newLit(fv, eLitFloat)
  of nnkStmtListExpr:
    result = toExpr(n[^1], cap)
  of nnkEmpty, nnkNilLit:
    glslErr("empty expression", n)
  of nnkCharLit:
    glslErr("char literals are not supported in shaders", n)
  of nnkStrLit:
    glslErr("string literals are not supported in shaders", n)
  else:
    glslErr("unsupported expression node kind: " & $n.kind, n)

proc collectConst(cap: var Capture, def: Def): Expr =
  ## Registers a module const (once) and returns a name reference to it.
  for c in cap.consts:
    if c.name == def.name:
      return newVar(def.name)
  let valueNode = def.value
  var value: Expr
  if valueNode.kind == nnkObjConstr:
    value = toExpr(valueNode, cap)
  else:
    value = toExpr(valueNode, cap)
  let typ = glslTypeOf(def.value.getTypeInst())
  cap.consts.add GlslConst(name: def.name, typ: typ, value: value)
  newVar(def.name)

proc toStmtList(n: NimNode, cap: var Capture, result: var seq[Stmt])

proc sectionStmts(sectionNode: NimNode, cap: var Capture,
                  isLet: bool, result: var seq[Stmt]) =
  for def in sectionNode:
    if def.kind == nnkEmpty:
      continue
    let (names, typNode, defVal) = splitIdentDefs(def)
    var init: Expr
    if defVal != nil:
      init = toExpr(defVal, cap)
    var typ = typNode
    if typ.kind == nnkEmpty:
      if defVal == nil:
        glslErr("declaration without a type or an initializer", def)
      typ = defVal.getTypeInst()
    let info = glslTypeOf(typ)
    for name in names:
      let n = name.strVal
      if n.isGlobalName:
        glslErr("cannot redeclare a GLSL global: " & n, name)
      cap.scope.bindName(n)
      let explicit = typNode.kind != nnkEmpty
      result.add declStmt(n, info, init, isLet, explicit, name.lineInfo)

proc toStmtList(n: NimNode, cap: var Capture, result: var seq[Stmt]) =
  case n.kind
  of nnkStmtList, nnkRecList:
    for child in n:
      toStmtList(child, cap, result)
  of nnkDiscardStmt:
    let s = newStmt(sDiscard, n.lineInfo)
    if n[0].kind notin {nnkEmpty, nnkNilLit}:
      s.discardArg = toExpr(n[0], cap)
    result.add s
  of nnkCommentStmt:
    let s = newStmt(sComment, n.lineInfo)
    s.commentText = n.strVal
    result.add s
  of nnkAsgn:
    let s = newStmt(sAssign, n.lineInfo)
    s.target = toExpr(n[0], cap)
    s.value = toExpr(n[1], cap)
    result.add s
  of nnkInfix:
    if n[0].kind == nnkSym and n[0].strVal.endsWith("=") and
        n[0].strVal notin ["==", "<=", ">="]:
      let s = newStmt(sAssignOp, n.lineInfo)
      s.assignOp = n[0].strVal[0 .. ^2]
      s.opTarget = toExpr(n[1], cap)
      s.opValue = toExpr(n[2], cap)
      result.add s
      return
    let s = newStmt(sExpr, n.lineInfo)
    s.expr = toExpr(n, cap)
    result.add s
  of nnkCall:
    let callee = n[0]
    if callee.kind in {nnkSym, nnkIdent}:
      let name = callee.strVal
      if name in ["inc", "dec"]:
        let s = newStmt(sAssignOp, n.lineInfo)
        s.assignOp = if name == "inc": "+" else: "-"
        s.opTarget = toExpr(n[1], cap)
        s.opValue = if n.len > 2:
          toExpr(n[2], cap)
        else:
          newLit("1", eLitInt)
        result.add s
        return
      if name in ["echo", "debugEcho"]:
        glslErr("echo is not available inside a shader; remove the call", n)
    let e = toExpr(n, cap)
    let s = newStmt(sExpr, n.lineInfo)
    s.expr = e
    result.add s
  of nnkIfStmt:
    let s = newStmt(sIf, n.lineInfo)
    for branch in n:
      case branch.kind
      of nnkElifBranch:
        var br: Branch
        br.isElse = false
        br.cond = toExpr(condOf(branch[0]), cap)
        toStmtList(branch[1], cap, br.body)
        s.branches.add br
      of nnkElse:
        var br: Branch
        br.isElse = true
        toStmtList(branch[0], cap, br.body)
        s.branches.add br
      else:
        glslErr("unsupported if branch", branch)
    result.add s
  of nnkWhileStmt:
    let s = newStmt(sWhile, n.lineInfo)
    s.whileCond = toExpr(condOf(n[0]), cap)
    toStmtList(n[1], cap, s.whileBody)
    result.add s
  of nnkForStmt:
    let s = newStmt(sFor, n.lineInfo)
    if n[0].kind == nnkSym:
      s.forVar = n[0].strVal
    elif n[0].kind == nnkIdent:
      s.forVar = n[0].strVal
    else:
      glslErr("unsupported loop variable", n[0])
    let iter = n[1]
    case iter.kind
    of nnkInfix:
      case iter[0].strVal
      of "..<":
        s.forStart = toExpr(iter[1], cap)
        s.forEnd = toExpr(iter[2], cap)
        s.forInclusive = false
        s.forStep = 1
      of "..":
        s.forStart = toExpr(iter[1], cap)
        s.forEnd = toExpr(iter[2], cap)
        s.forInclusive = true
        s.forStep = 1
      else:
        glslErr("only .. and ..< ranges are supported in shader " &
          "for-loops", iter)
    of nnkCall:
      case iter[0].strVal
      of "countup":
        s.forStart = toExpr(iter[1], cap)
        s.forEnd = toExpr(iter[2], cap)
        s.forInclusive = true
        let step = if iter.len > 3: iter[3].unwrapConstInt else: 1
        if step <= 0:
          glslErr("countup requires a positive step", iter)
        s.forStep = step
      of "countdown":
        s.forStart = toExpr(iter[1], cap)
        s.forEnd = toExpr(iter[2], cap)
        s.forInclusive = true
        let step = if iter.len > 3: iter[3].unwrapConstInt else: 1
        if step <= 0:
          glslErr("countdown requires a positive step", iter)
        s.forStep = -step
      else:
        glslErr("only countup/countdown loops are supported in shaders; " &
          "not " & iter[0].strVal, iter)
    else:
      glslErr("unsupported loop iterator", iter)
    if s.forVar.isGlobalName:
      glslErr("loop variable collides with a GLSL global: " & s.forVar, n)
    cap.scope.bindName(s.forVar)
    toStmtList(n[2], cap, s.forBody)
    result.add s
  of nnkCaseStmt:
    let s = newStmt(sSwitch, n.lineInfo)
    s.switchValue = toExpr(n[0], cap)
    for branch in n[1 .. ^1]:
      case branch.kind
      of nnkOfBranch:
        var br = SwitchBranch(isElse: false)
        for vi in 0 ..< branch.len - 1:
          let v = branch[vi]
          if v.kind in {nnkIntLit .. nnkInt64Lit}:
            br.values.add $v.intVal
          elif v.kind == nnkSym:
            br.values.add v.strVal
          else:
            glslErr("unsupported case value", v)
        toStmtList(branch[^1], cap, br.body)
        s.caseBranches.add br
      of nnkElse:
        var br = SwitchBranch(isElse: true)
        toStmtList(branch[0], cap, br.body)
        s.caseBranches.add br
      else:
        glslErr("unsupported case branch", branch)
    if s.caseBranches.len == 0:
      glslErr("empty case statement", n)
    result.add s
  of nnkReturnStmt:
    if n[0].kind == nnkEmpty or n[0].kind == nnkNilLit:
      let s = newStmt(sReturn, n.lineInfo)
      s.returnValue = nil
      result.add s
    elif n[0].kind == nnkAsgn:
      # `return x` in a result-proc compiles to a result assignment.
      let asn = newStmt(sAssign, n.lineInfo)
      asn.target = toExpr(n[0][0], cap)
      asn.value = toExpr(n[0][1], cap)
      result.add asn
      let s = newStmt(sReturn, n.lineInfo)
      s.returnValue = nil
      s.returnResult = true
      result.add s
    else:
      let s = newStmt(sReturn, n.lineInfo)
      s.returnValue = toExpr(n[0], cap)
      result.add s
  of nnkBreakStmt:
    result.add newStmt(sBreak, n.lineInfo)
  of nnkContinueStmt:
    result.add newStmt(sContinue, n.lineInfo)
  of nnkVarSection:
    sectionStmts(n, cap, isLet = false, result)
  of nnkLetSection:
    sectionStmts(n, cap, isLet = true, result)
  of nnkPragma, nnkEmpty, nnkNilLit:
    discard
  of nnkStmtListExpr:
    toStmtList(n[^1], cap, result)
  of nnkBlockStmt:
    toStmtList(n[^1], cap, result)
  of nnkProcDef, nnkFuncDef, nnkIteratorDef:
    glslErr("nested proc definitions are not allowed in shaders", n)
  else:
    glslErr("unsupported statement kind: " & $n.kind, n)

proc paramInfo(typNode: NimNode): tuple[io: ParamIo, typ: GlslTypeInfo,
    location: int, instanced: bool, attrTypeName: string] =
  ## Classifies a param type node (already unwrapped of VarTy).
  if typNode.kind == nnkBracketExpr:
    let head = typNode[0].strVal
    case head
    of "Layout", "Batch":
      let elem = typNode[2]
      let loc = if typNode[1].kind in
          {nnkIntLit .. nnkInt64Lit}:
        typNode[1].intVal.int
      else:
        glslErr("Layout location must be an integer literal", typNode[1])
      result.location = loc
      result.instanced = head == "Batch"
      result.attrTypeName = elem.strVal
      result.typ = glslTypeOf(elem)
      result.io = piLayoutIn
      return
    of "Uniform", "UniformWriteOnly":
      result.typ = glslTypeOf(typNode[1])
      result.io = piUniform
      return
    of "Attribute":
      glslErr("legacy Attribute[N, T] is no longer supported; use " &
        "Layout[N, T]", typNode)
    else:
      discard
  let info = glslTypeOf(typNode)
  if info.shape == tsSampler:
    glslErr("sampler params must be wrapped as Uniform[SamplerX]; found " &
      "the bare type " & typNode.strVal, typNode)
  result.typ = info
  result.io = piValue

proc captureParams(fparams: NimNode, scope: var Scope,
                  isHelper: bool): seq[ParamDecl] =
  if fparams.kind != nnkFormalParams:
    glslErr("expected formal params", fparams)
  var paramList: seq[ParamDecl]
  for i in 1 ..< fparams.len:
    let def = fparams[i]
    if def.kind == nnkEmpty:
      continue
    if def.kind == nnkSym:
      glslErr("shader procs cannot have a return type; use out parameters " &
        "instead", def)
    let (names, typNode, defVal) = splitIdentDefs(def)
    if defVal != nil:
      glslErr("shader parameters cannot have default values", def)
    let isVar = typNode.kind == nnkVarTy
    let (io, typ, loc, inst, attrName) = paramInfo(typNode.unwrap())
    for name in names:
      let nm = name.strVal
      if nm.isGlobalName:
        # gl_* globals are implicit; do not declare, just allow use.
        continue
      scope.bindName(nm)
      var p = ParamDecl(name: nm, glslType: typ,
        io: (if isVar: (if isHelper: piInOut else: piOut) else: io),
        location: loc, instanced: inst, attrTypeName: attrName)
      if isVar and typ.shape == tsSampler:
        glslErr("samplers cannot be var/out params: " & nm, def)
      paramList.add p
  result = paramList

proc captureFn(impl: NimNode, cap: var Capture, kind: FnKind,
               entryName: string): GlslFn =
  if impl.kind notin {nnkProcDef, nnkFuncDef}:
    glslErr("expected a proc/func definition, got " & $impl.kind, impl)
  result = GlslFn(kind: kind, name: entryName)
  for n in impl:
    case n.kind
    of nnkSym:
      if kind == fkHelper:
        result.name = n.strVal
    of nnkFormalParams:
      result.params = captureParams(n, cap.scope, kind == fkHelper)
      if kind == fkHelper and n[0].kind != nnkEmpty:
        result.retType = glslTypeOf(n[0])
        cap.scope.bindName("result")
    of nnkStmtList, nnkAsgn, nnkIfStmt, nnkLetSection, nnkVarSection,
        nnkCall, nnkInfix, nnkDiscardStmt, nnkReturnStmt,
        nnkWhileStmt, nnkForStmt, nnkCaseStmt, nnkCommentStmt,
        nnkBreakStmt, nnkContinueStmt, nnkBlockStmt, nnkStmtListExpr:
      result.body = @[]
      toStmtList(n, cap, result.body)
    else:
      discard
  if kind == fkHelper:
    result.usesResult = resultUsage(impl)
  result.name = entryName

proc collectCalls(body: NimNode, cap: var Capture) =
  ## Walks every node, pulling in helper procs and consts on demand.
  for n in body.children:
    case n.kind
    of nnkSym:
      # the shader's own symbol is not a definition to pull in.
      if n.strVal == cap.entryName and n.lineInfo == cap.entryInfo:
        continue
      let def = cap.scope.analyze(n)
      case def.kind
      of defHelper:
        if def.value.lineInfo != cap.entryInfo:
          callHelper(cap, n, def.value)
      of defConst:
        discard collectConst(cap, def)
      else:
        discard
    of nnkCall:
      let callee = n[0]
      if callee.kind in {nnkSym, nnkIdent}:
        let def = cap.scope.analyze(callee)
        case def.kind
        of defHelper:
          if def.value.lineInfo != cap.entryInfo:
            callHelper(cap, callee, def.value)
        else:
          discard
      elif callee.kind == nnkDotExpr:
        let def = cap.scope.analyze(callee[1])
        case def.kind
        of defHelper:
          if def.value.lineInfo != cap.entryInfo:
            callHelper(cap, callee[1], def.value)
        else:
          discard
      collectCalls(n, cap)
    else:
      collectCalls(n, cap)

proc captureUnit*(entry: NimNode, extraFiles: seq[string]): tuple[
  unit: GlslUnit, cap: Capture] =
  ## Full capture of a shader proc (its impl) into the IR.
  var cap: Capture
  cap.scope = newScope(entry, extraFiles)
  cap.entryInfo = entry.lineInfo
  if entry.kind in {nnkProcDef, nnkFuncDef} and entry[0].kind == nnkSym:
    cap.entryName = entry[0].strVal
  let fn = captureFn(entry, cap, fkEntry, "main")
  collectCalls(entry, cap)
  result.cap = cap
  result.unit = GlslUnit(fn: fn, helpers: cap.helpers, consts: cap.consts)
