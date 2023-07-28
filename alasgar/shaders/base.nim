import hashes
import strformat
import strutils
import tables

import ../ports/opengl
import ../utils
import ../container
import ../texture

import compile, forward, effect

type
    ShaderValueKind* = enum
        svUint, svInt, svFloat, svVec2, svVec3, svVec4, svColor, svMat3, svMat4, svTexture
    ShaderValue {.union.} = object
        uintVal: uint32
        intVal: int32
        floatVal: float32
        vec2Val: Vec2
        vec3Val: Vec3
        vec4Val: Vec4
        colorVal: Color
        mat3Val: Mat3
        mat4Val: Mat4
        textureVal: Texture
    ShaderParam = ref object
        kind: ShaderValueKind
        value: ShaderValue
        extra: int
    Shader* = ref object
        program*: GLuint
        attributeCount: int
        map: Table[string, GLint]
        params: Table[string, ShaderParam]
        source: string

proc destroyShader(shader: Shader) =
    if shader.program != 0:
        echo &"Destroying shader[{shader.program}]..."
        glDeleteProgram(shader.program)
        shader.program = 0

var cache = newCachedContainer[Shader](destroyShader)

proc hash*(o: Shader): Hash = 
    if o != nil:
        int(o.program)
    else:
        0

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
        var infoLog : cstring = cast[cstring](alloc(infoLen + 1))
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
        var infoLog : cstring = cast[cstring](alloc(infoLen + 1))
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
        #echo(vs)
        #echo(fs)
        halt &"Could not link: {programInfoLog(result)}"


proc newShader*(vs, fs: string, attributeCount: int): Shader =
    new(result)
    result.program = createProgram(
        vs, 
        fs,
    )
    result.attributeCount = attributeCount
    result.source = &"{vs}\n{fs}"
    add(cache, result)
    

proc getUniformLocation*(s: Shader, key: string): GLint =
    if not s.map.hasKey(key):
        s.map[key] = glGetUniformLocation(s.program, key)
    result = s.map[key]
    
proc getAttributeLocation*(s: Shader, key: string): GLint = glGetAttribLocation(s.program, key)

proc `[]=`*(s: Shader; key: string; value: Vec2) =
    var location = getUniformLocation(s, key)
    var data = value
    glUniform2fv location, 1, data.caddr

proc `[]=`*(s: Shader; key: string; value: Vec3) =
    var location = getUniformLocation(s, key)
    var data = value
    glUniform3fv location, 1, data.caddr

proc `[]=`*(s: Shader; key: string; value: Vec4) =
    var location = getUniformLocation(s, key)
    var data = value
    glUniform4fv location, 1, data.caddr

proc `[]=`*(s: Shader; key: string; value: Color) =
    var location = getUniformLocation(s, key)
    var data = vec4(value.r, value.g, value.b, value.a)
    glUniform4fv location, 1, data.caddr

proc `[]=`*(s: Shader; key: string; value: float32) =
    var location = getUniformLocation(s, key)
    glUniform1f location, value


proc `[]=`*(s: Shader; key: string; value: int) =
    var location = getUniformLocation(s, key)
    glUniform1i location, value.GLint

proc `[]=`*(s: Shader; key: string; value: uint32) =
    var location = getUniformLocation(s, key)
    glUniform1ui location, value.GLuint

proc `[]=`*(s: Shader; key: string; value: var Mat4) =
    var location = getUniformLocation(s, key)
    glUniformMatrix4fv location, 1, false, value.caddr

proc `[]=`*(s: Shader; key: string; value: ptr Mat4) =
    var location = getUniformLocation(s, key)
    glUniformMatrix4fv location, 1, false, value[].caddr

proc `[]=`*(s: Shader, key: string, value: Mat4) =
    var matrix = value
    s[key] = matrix

proc `[]=`*(s: Shader; key: string; value: var Mat3) =
    var location = getUniformLocation(s, key)
    glUniformMatrix3fv location, 1, false, value.caddr

proc `[]=`*(s: Shader, key: string, value: Mat3) =
    var matrix = value
    s[key] = matrix

#proc `[]`*(s: Shader, key: string): int = getUniformLocation(s, key).int

#method update(p: ShaderParamTexture, shader: Shader) = 
#    shader[p.key] = p.slot
#    unit(p.value, p.slot)

proc get*(shader: Shader, key: string, r: var uint32) = r = shader.params[key].value.uintVal
proc get*(shader: Shader, key: string, r: var int32) = r = shader.params[key].value.intVal
proc get*(shader: Shader, key: string, r: var int) = r = shader.params[key].value.intVal.int
proc get*(shader: Shader, key: string, r: var float32) = r = shader.params[key].value.floatVal
proc get*(shader: Shader, key: string, r: var Vec2) = r = shader.params[key].value.vec2Val
proc get*(shader: Shader, key: string, r: var Vec3) = r = shader.params[key].value.vec3Val
proc get*(shader: Shader, key: string, r: var Vec4) = r = shader.params[key].value.vec4Val
proc get*(shader: Shader, key: string, r: var Mat3) = r = shader.params[key].value.mat3Val
proc get*(shader: Shader, key: string, r: var Mat4) = r = shader.params[key].value.mat4Val
proc get*(shader: Shader, key: string, r: var Color) = r = shader.params[key].value.colorVal

proc set*(shader: Shader, key: string, value: uint32) =
    shader.params[key] = ShaderParam(
        kind: svUint, 
        value: ShaderValue(
            uintVal: value
        )
    )

proc set*(shader: Shader, key: string, value: int32) =
    shader.params[key] = ShaderParam(
        kind: svInt, 
        value: ShaderValue(
            intVal: value
        )
    )

proc set*(shader: Shader, key: string, value: int) = set(shader, key, value.int32)

proc set*(shader: Shader, key: string, value: float32) =
    shader.params[key] = ShaderParam(
        kind: svFloat, 
        value: ShaderValue(
            floatVal: value
        )
    )

proc set*(shader: Shader, key: string, value: Vec2) =
    shader.params[key] = ShaderParam(
        kind: svVec2, 
        value: ShaderValue(
            vec2Val: value
        )
    )

proc set*(shader: Shader, key: string, value: Vec3) =
    shader.params[key] = ShaderParam(
        kind: svVec3, 
        value: ShaderValue(
            vec3Val: value
        )
    )

proc set*(shader: Shader, key: string, value: Vec4) =
    shader.params[key] = ShaderParam(
        kind: svVec4, 
        value: ShaderValue(
            vec4Val: value
        )
    )

proc set*(shader: Shader, key: string, value: Color) =
    shader.params[key] = ShaderParam(
        kind: svColor, 
        value: ShaderValue(
            colorVal: value
        )
    )

proc set*(shader: Shader, key: string, value: Mat4) =
    shader.params[key] = ShaderParam(
        kind: svMat4, 
        value: ShaderValue(
            mat4Val: value
        )
    )

proc set*(shader: Shader, key: string, value: Texture, slot: int) =
    shader.params[key] = ShaderParam(
        kind: svTexture, 
        value: ShaderValue(
            textureVal: value
        ),
        extra: slot
    )

proc hasUniform*(shader: Shader, name: string): bool =
    var location = getUniformLocation(shader, name)
    result = location >= 0

proc use*(shader: Shader, texture: Texture, name: string, slot: int) =
    #echo &"Setting [{name}] to [{slot}] for shader [{shader.program}]"
    var location = getUniformLocation(shader, name)
    if location >= 0:
        shader[name] = slot
        unit(texture, slot)

proc update(shader: Shader, key: string, p: ShaderParam) =
    case p.kind:
        of svUint: shader[key] = p.value.uintVal
        of svInt: shader[key] = p.value.intVal
        of svFloat: shader[key] = p.value.floatVal
        of svVec2: shader[key] = p.value.vec2Val
        of svVec3: shader[key] = p.value.vec3Val
        of svVec4: shader[key] = p.value.vec4Val
        of svColor: shader[key] = p.value.colorVal
        of svMat3: shader[key] = p.value.mat3Val
        of svMat4: shader[key] = p.value.mat4Val
        of svTexture: 
            use(shader, p.value.textureVal, key, p.extra)

# In threading, this can cause a crash
var lastAttributeCount = 0

proc updateAttributes(shader: Shader) =
    if lastAttributeCount < shader.attributeCount:
        for i in lastAttributeCount..<shader.attributeCount:
            glEnableVertexAttribArray(i.GLuint)
    elif lastAttributeCount > shader.attributeCount:
        for i in shader.attributeCount..<lastAttributeCount:
            glDisableVertexAttribArray(i.GLuint)
    if shader.attributeCount == 0:
        glDisableVertexAttribArray(0)

    lastAttributeCount = shader.attributeCount      

proc use*(shader: Shader) =
    #updateAttributes(shader)    
    glUseProgram(shader.program)
    for key, param in pairs(shader.params):
        update(shader, key, param)

proc destroy*(shader: Shader) = remove(cache, shader)
proc cleanupShaders*() =
    echo &"Cleaning up [{len(cache)}] shaders..."
    clear(cache)

template newSpatialShader*(vx, fs: untyped): Shader = 
    let 
        vs: (string, int) = compileToGLSL(vx)
        fs = toGLSL(fs)
    newShader(vs[0], fs, vs[1])
template newSpatialShader*(fs: untyped): Shader = newSpacialShader(mainVertex, fs)
proc newSpatialShader*(): Shader = newSpatialShader(mainVertex, mainFragment)

template newCanvasShader*(vx, fs: untyped): Shader = newSpatialShader(vx, fs)
template newCanvasShader*(fs: untyped): Shader = newCanvasShader(effectVertex, fs)
proc newCanvasShader*(): Shader = newCanvasShader(effectVertex, effectFragment)
