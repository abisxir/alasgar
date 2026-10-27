## Renders the GLSL IR into shader source text.
##
## This module never inspects Nim AST nodes or scans generated strings:
## formatting is driven by IR structure and explicit indentation state.

import std/strutils

import ir

proc lineOf(info: string): int =
  let paren = info.find('(')
  let comma = info.rfind(',')
  if paren > 0 and comma > paren:
    try:
      return parseInt(info[paren + 1 ..< comma])
    except ValueError:
      discard
  result = 0

proc emitExpr(e: Expr, res: var string, parentPrec = -1)

proc needsParensForBase(e: Expr): bool =
  case e.kind
  of eVar, eField, eIndex, eCall, eLitFloat, eLitInt:
    false
  of eSwizzle:
    false
  else:
    true

proc emitExpr(e: Expr, res: var string, parentPrec = -1) =
  case e.kind
  of eVar:
    res.add e.name
  of eField:
    emitExpr(e.children[0], res)
    res.add "."
    emitExpr(e.children[1], res)
  of eSwizzle:
    if needsParensForBase(e.children[0]):
      res.add "("
      emitExpr(e.children[0], res)
      res.add ")"
    else:
      emitExpr(e.children[0], res)
    res.add "."
    res.add e.name
  of eIndex:
    if needsParensForBase(e.children[0]):
      res.add "("
      emitExpr(e.children[0], res)
      res.add ")"
    else:
      emitExpr(e.children[0], res)
    res.add "["
    emitExpr(e.children[1], res)
    res.add "]"
  of eCall:
    res.add e.name
    res.add "("
    for i, arg in e.children:
      if i > 0:
        res.add ", "
      emitExpr(arg, res)
    res.add ")"
  of eBinary:
    # always fully parenthesize operator chains: no precedence guessing.
    res.add "("
    emitExpr(e.children[0], res)
    res.add " "
    res.add e.op
    res.add " "
    emitExpr(e.children[1], res)
    res.add ")"
  of ePrefix:
    res.add e.name
    res.add "("
    emitExpr(e.children[0], res)
    res.add ")"
  of eCast:
    res.add e.castType
    res.add "("
    emitExpr(e.value, res)
    res.add ")"
  of eLitFloat, eLitInt:
    res.add e.lit
  of eTernary:
    res.add "("
    emitExpr(e.cond, res)
    res.add ") ? ("
    emitExpr(e.thenExpr, res)
    res.add ") : ("
    emitExpr(e.elseExpr, res)
    res.add ")"

proc indent(res: var string, level: int) =
  for i in 0 ..< level:
    res.add "  "

proc addLineNo(res: var string, lineInfo: string) =
  let n = lineOf(lineInfo)
  if n > 0:
    res.add "#line "
    res.add $n
    res.add "\n"

proc emitStmt(s: Stmt, res: var string, level: int) =
  case s.kind
  of sDecl:
    indent(res, level)
    var typ = s.declType.glslName
    if s.declType.arraySize > 0:
      res.add typ
      res.add " "
      res.add s.declName
      res.add "["
      res.add $s.declType.arraySize
      res.add "]"
    else:
      res.add typ
      res.add " "
      res.add s.declName
    if s.declInit != nil:
      res.add " = "
      emitExpr(s.declInit, res)
    res.add ";\n"
  of sAssign:
    indent(res, level)
    emitExpr(s.target, res)
    res.add " = "
    emitExpr(s.value, res)
    res.add ";\n"
  of sAssignOp:
    indent(res, level)
    emitExpr(s.opTarget, res)
    res.add " "
    res.add s.assignOp
    res.add "= "
    emitExpr(s.opValue, res)
    res.add ";\n"
  of sExpr:
    indent(res, level)
    emitExpr(s.expr, res)
    res.add ";\n"
  of sIf:
    for i, br in s.branches:
      indent(res, level)
      if br.isElse:
        res.add "else {\n"
      else:
        if i == 0:
          res.add "if ("
        else:
          res.add "else if ("
        emitExpr(br.cond, res)
        res.add ") {\n"
      for stmt in br.body:
        emitStmt(stmt, res, level + 1)
      indent(res, level)
      res.add "}\n"
  of sSwitch:
    indent(res, level)
    res.add "switch("
    emitExpr(s.switchValue, res)
    res.add ") {\n"
    for br in s.caseBranches:
      indent(res, level + 1)
      if br.isElse:
        res.add "default: {\n"
      else:
        res.add "case "
        for vi, v in br.values:
          if vi > 0:
            res.add ", "
          res.add v
        res.add ": {\n"
      for stmt in br.body:
        emitStmt(stmt, res, level + 2)
      let lastStmt = if br.body.len > 0: br.body[^1] else: nil
      if lastStmt == nil or
          lastStmt.kind notin {sBreak, sReturn}:
        indent(res, level + 2)
        res.add "break;\n"
      indent(res, level + 1)
      res.add "}\n"
    indent(res, level)
    res.add "}\n"
  of sFor:
    indent(res, level)
    res.add "for(int "
    res.add s.forVar
    res.add " = "
    emitExpr(s.forStart, res)
    res.add "; "
    res.add s.forVar
    if s.forStep < 0:
      res.add (if s.forInclusive: " >= " else: " > ")
    else:
      res.add (if s.forInclusive: " <= " else: " < ")
    emitExpr(s.forEnd, res)
    res.add "; "
    res.add s.forVar
    if s.forStep == 1:
      res.add "++"
    elif s.forStep == -1:
      res.add "--"
    elif s.forStep < -1:
      res.add " -= "
      res.add $(-s.forStep)
    else:
      res.add " += "
      res.add $s.forStep
    res.add ") {\n"
    for stmt in s.forBody:
      emitStmt(stmt, res, level + 1)
    indent(res, level)
    res.add "}\n"
  of sWhile:
    indent(res, level)
    res.add "while("
    emitExpr(s.whileCond, res)
    res.add ") {\n"
    for stmt in s.whileBody:
      emitStmt(stmt, res, level + 1)
    indent(res, level)
    res.add "}\n"
  of sReturn:
    indent(res, level)
    if s.returnResult:
      res.add "return result;"
    elif s.returnValue != nil:
      res.add "return "
      emitExpr(s.returnValue, res)
      res.add ";"
    else:
      res.add "return;"
    res.add "\n"
  of sBreak:
    indent(res, level)
    res.add "break;\n"
  of sContinue:
    indent(res, level)
    res.add "continue;\n"
  of sDiscard:
    if s.discardArg == nil:
      indent(res, level)
      res.add "discard;\n"
    else:
      indent(res, level)
      emitExpr(s.discardArg, res)
      res.add ";\n"
  of sComment:
    indent(res, level)
    res.add "// "
    res.add s.commentText
    res.add "\n"

proc emitStmts(stmts: seq[Stmt], res: var string, level: int,
               withLines: bool) =
  for s in stmts:
    if withLines:
      addLineNo(res, s.lineInfo)
    emitStmt(s, res, level)

proc ioKeyword(io: ParamIo): string =
  case io
  of piValue: ""
  of piInOut: "inout "
  of piOut, piLayoutOut: "out "
  of piUniform: ""
  of piLayoutIn: ""

proc paramSig(p: ParamDecl): string =
  result = ioKeyword(p.io) & p.glslType.glslName & " " & p.name
  if p.glslType.arraySize > 0:
    result.add "["
    result.add $p.glslType.arraySize
    result.add "]"

proc emitFnSignature(res: var string, fn: GlslFn) =
  if fn.retType.glslName.len > 0:
    res.add fn.retType.glslName
    res.add " "
  else:
    res.add "void "
  res.add fn.name
  res.add "("
  var first = true
  for p in fn.params:
    if not first:
      res.add ", "
    res.add p.paramSig
    first = false
  res.add ")\n"

proc emitFn*(res: var string, fn: GlslFn) =
  emitFnSignature(res, fn)
  res.add "{\n"
  if fn.usesResult and fn.retType.glslName.len > 0:
    res.add "  "
    res.add fn.retType.glslName
    res.add " result;\n"
  emitStmts(fn.body, res, 1, withLines = true)
  res.add "}\n"

proc emitConst(res: var string, c: GlslConst) =
  res.add "const "
  res.add c.typ.glslName
  res.add " "
  res.add c.name
  res.add " = "
  emitExpr(c.value, res)
  res.add ";\n\n"

proc emitUnitBody*(res: var string, unit: GlslUnit) =
  for c in unit.consts:
    emitConst(res, c)
  for fn in unit.helpers:
    emitFn(res, fn)
    res.add "\n"

proc emitMain*(res: var string, unit: GlslUnit) =
  ## Emits the global parameter declarations and the main() function.
  let fn = unit.fn
  for p in fn.params:
    case p.io
    of piValue:
      res.add "in "
    of piUniform:
      res.add "uniform "
    of piOut:
      res.add "out "
    of piInOut:
      res.add "inout "
    of piLayoutIn:
      res.add "layout(location="
      res.add $p.location
      res.add ") in "
    of piLayoutOut:
      res.add "layout(location="
      res.add $p.location
      res.add ") out "
    res.add p.glslType.glslName
    if p.glslType.arraySize > 0:
      res.add "["
      res.add $p.glslType.arraySize
      res.add "]"
    res.add " "
    res.add p.name
    res.add ";\n"
  res.add "\n"
  res.add "void main() {\n"
  emitStmts(fn.body, res, 1, withLines = true)
  res.add "}\n"
