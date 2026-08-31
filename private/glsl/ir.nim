## Intermediate representation for the GLSL compiler.
##
## The typed Nim AST is *captured* into this minimal, compiler-owned IR.
## The emitter only knows about IR nodes, which keeps generation free of
## AST-shape guessing and string heuristics.

import typeinfo

type
  ParamIo* = enum
    piValue       ## in (input)
    piOut         ## out (param was `var`, entry stage)
    piInOut       ## inout (param was `var`, helper function)
    piUniform     ## uniform
    piLayoutIn    ## layout(location=N) in + attribute metadata
    piLayoutOut   ## layout(location=N) out + attribute metadata

  ParamDecl* = object
    name*: string
    glslType*: GlslTypeInfo
    io*: ParamIo
    location*: int        ## pixel location for layout/batch params.
    instanced*: bool      ## batch attribute.
    attrTypeName*: string ## Nim type name recorded for ShaderAttribute.

  ExprKind* = enum
    eVar        ## plain variable / global.
    eField      ## base.name where name is a struct/vec field.
    eSwizzle    ## base.xyz where the swizzle came from a call.
    eIndex      ## base[i].
    eCall       ## builtin function call / constructor.
    eBinary     ## binary operator (GLSL spelling in `op`).
    ePrefix     ## unary operator (GLSL spelling in `name`).
    eCast       ## type conversion.
    eLitFloat
    eLitInt
    eTernary    ## cond ? yes : no

  Expr* = ref ExprObj
  ExprObj* = object
    case kind*: ExprKind
    of eVar, eField, eSwizzle, eCall, ePrefix:
      name*: string
    of eBinary:
      op*: string
    of eCast:
      castType*: string
      value*: Expr
    of eLitFloat, eLitInt:
      lit*: string
    of eTernary:
      cond*: Expr
      thenExpr*: Expr
      elseExpr*: Expr
    else: discard
    children*: seq[Expr]
    lineInfo*: string

  StmtKind* = enum
    sDecl        ## var/let declaration.
    sAssign
    sAssignOp    ## target op= value.
    sExpr        ## expression statement (side-effect call).
    sIf
    sSwitch
    sFor
    sWhile
    sReturn
    sBreak
    sContinue
    sDiscard
    sComment

  Branch* = object
    isElse*: bool
    cond*: Expr           ## nil for else.
    body*: seq[Stmt]

  SwitchBranch* = object
    isElse*: bool
    values*: seq[string]  ## case values (for non-else branches).
    body*: seq[Stmt]

  Stmt* = ref StmtObj
  StmtObj* = object
    case kind*: StmtKind
    of sDecl:
      declName*: string
      declType*: GlslTypeInfo
      declLet*: bool             ## let vs var (both emit the same in GLSL).
      declInit*: Expr
      declExplicitType*: bool
    of sAssign:
      target*: Expr
      value*: Expr
    of sAssignOp:
      assignOp*: string
      opTarget*: Expr
      opValue*: Expr
    of sExpr:
      expr*: Expr
    of sIf:
      branches*: seq[Branch]
    of sSwitch:
      switchValue*: Expr
      caseBranches*: seq[SwitchBranch]
    of sFor:
      forVar*: string
      forStart*: Expr
      forEnd*: Expr
      forStep*: int           ## +1 / -1 / other.
      forInclusive*: bool
      forBody*: seq[Stmt]
    of sWhile:
      whileCond*: Expr
      whileBody*: seq[Stmt]
    of sReturn:
      returnValue*: Expr
      returnResult*: bool     ## `return result` after assigning `result`.
    of sComment:
      commentText*: string
    of sDiscard:
      discardArg*: Expr
    else: discard
    lineInfo*: string

  FnKind* = enum
    fkEntry      ## the shader itself; becomes void main().
    fkHelper     ## gathered helper proc.

  GlslFn* = object
    kind*: FnKind
    name*: string
    retType*: GlslTypeInfo  ## glslName == "" for void.
    usesResult*: bool
    params*: seq[ParamDecl]
    body*: seq[Stmt]

  GlslConst* = object
    name*: string
    typ*: GlslTypeInfo
    value*: Expr

  GlslUnit* = object
    fn*: GlslFn
    helpers*: seq[GlslFn]
    consts*: seq[GlslConst]

proc newExpr*(kind: ExprKind, lineInfo = ""): Expr =
  Expr(kind: kind, lineInfo: lineInfo)

proc newCall*(name: string, args: seq[Expr], lineInfo = ""): Expr =
  result = newExpr(eCall, lineInfo)
  result.name = name
  result.children = args

proc newVar*(name: string, lineInfo = ""): Expr =
  result = newExpr(eVar, lineInfo)
  result.name = name

proc newField*(base, field: Expr, lineInfo = ""): Expr =
  result = newExpr(eField, lineInfo)
  result.children = @[base, field]

proc newBinary*(op: string, l, r: Expr, lineInfo = ""): Expr =
  result = newExpr(eBinary, lineInfo)
  result.op = op
  result.children = @[l, r]

proc newPref*(op: string, arg: Expr, lineInfo = ""): Expr =
  result = newExpr(ePrefix, lineInfo)
  result.name = op
  result.children = @[arg]


proc newIndex*(base, idx: Expr, lineInfo = ""): Expr =
  result = newExpr(eIndex, lineInfo)
  result.children = @[base, idx]

proc newLit*(v: string, kind: ExprKind): Expr =
  result = newExpr(kind)
  result.lit = v

proc newStmt*(kind: StmtKind, lineInfo = ""): Stmt =
  Stmt(kind: kind, lineInfo: lineInfo)

proc declStmt*(name: string, typ: GlslTypeInfo, init: Expr,
               letToGLSL, declared: bool, lineInfo = ""): Stmt =
  Stmt(kind: sDecl, lineInfo: lineInfo, declName: name, declType: typ,
    declInit: init, declLet: letToGLSL, declExplicitType: declared)
