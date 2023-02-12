import hashes
import strformat
import strutils
import tables

import config
import ports/opengl
import utils
import container
import texture

const forwardV = staticRead("render/shaders/forward.vs")
const forwardF = staticRead("render/shaders/forward.fs")
const forwardPostV = staticRead("render/shaders/effect.vs")
const forwardPostF = staticRead("render/shaders/effect.fs")

type
    Shader* = ref object
        program*: GLuint
        map: Table[string, GLint]
        params: Table[string, ShaderParam]

    ShaderParam* = ref object of RootObj
        key: string  
    ShaderParamInt* = ref object of ShaderParam
        value: int32
    ShaderParamFloat* = ref object of ShaderParam
        value: float32
    ShaderParamVec2* = ref object of ShaderParam
        value: Vec2
    ShaderParamVec3* = ref object of ShaderParam
        value: Vec3
    ShaderParamVec4* = ref object of ShaderParam
        value: Vec4
    ShaderParamMat4* = ref object of ShaderParam
        value: Mat4
    ShaderParamTexture* = ref object of ShaderParam
        value: Texture
        slot: int

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

proc extractLineNo(line: string): int =
    result = -1
    let step1 = split(line, "(")
    if len(step1) > 1:
        let step2 = split(step1[0], ":")
        if len(step2) > 1:
            result = parseInt(step2[1])

proc safeOutput(lines: openarray[string], lineNo: int) =
    if lineNo < len(lines):
        echo lines[lineNo]

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
        let 
            lineNo = extractLineNo(info)
            lines = split(&"{$src}", "\n")
        logi "The shader: ", src
        logi "Shader compile error: ", info
        if lineNo > 0 and lineNo < len(lines):
            logi "-> ", lines[lineNo - 1], "\n"
        glDeleteShader(result)
    elif info.len > 0:
        logi "Shader compile log: ", info


proc createProgram*(vs, fs: string,
        attributes: openarray[tuple[index: GLuint, name: string]]): GLuint =
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

    for a in attributes:
        glBindAttribLocation(result, a.index, a.name.cstring)

    glLinkProgram(result)
    glDeleteShader(vShader)
    glDeleteShader(fShader)

    let linked = isProgramLinked(result)
    if not linked:
        halt &"Could not link: {programInfoLog(result)}"


proc createProgram*(cs: string): GLuint =
    result = glCreateProgram()
    if result == 0:
        halt &"Could not create program: {glGetError().int}" 
    let csShader = loadShaderSource(cs, GL_COMPUTE_SHADER)
    if csShader == 0:
        glDeleteProgram(result)
        halt &"Could not create compute shader: {glGetError().int}" 

    glAttachShader(result, csShader)

    glLinkProgram(result)
    glDeleteShader(csShader)

    let linked = isProgramLinked(result)
    if not linked:
        halt &"Could not link: {programInfoLog(result)}"

proc newShader*(vs, fs: string, attributes: openarray[tuple[index: GLuint, name: string]]): Shader =
    new(result)
    when defined(macosx):
        let shaderProfile = "#version 410"
    else:
        let shaderProfile = "#version 310 es"
    
    result.program = createProgram(
        vs.replace("$SHADER_PROFILE$", shaderProfile), 
        fs.replace("$SHADER_PROFILE$", shaderProfile), attributes)

    add(cache, result)
    

proc newComputeShader*(cs: string): Shader =
    new(result)
    when defined(macosx):
        let shaderProfile = "#version 410"
    else:
        let shaderProfile = "#version 310 es"
    
    result.program = createProgram(cs.replace("$SHADER_PROFILE$", shaderProfile))

    add(cache, result)

proc compute*(xGroups, yGroups, zGroups: int) =
    glDispatchCompute(xGroups.GLuint, yGroups.GLuint, zGroups.GLuint)
    let error = glGetError() != GL_NO_ERROR.GLenum
    if error:
        echo "error -> ", glGetError().int
    glMemoryBarrier(GL_TEXTURE_FETCH_BARRIER_BIT or GL_SHADER_IMAGE_ACCESS_BARRIER_BIT)

proc getKeyLocation(s: Shader, key: string): GLint =
    if not s.map.hasKey(key):
        s.map[key] = glGetUniformLocation(s.program, key)
    result = s.map[key]


proc `[]=`*(s: Shader; key: string; value: Vec2) =
    var location = s.getKeyLocation key
    var data = value
    glUniform2fv location, 1, data.caddr

proc `[]=`*(s: Shader; key: string; value: Vec3) =
    var location = s.getKeyLocation key
    var data = value
    glUniform3fv location, 1, data.caddr

proc `[]=`*(s: Shader; key: string; value: Vec4) =
    var location = s.getKeyLocation key
    var data = value
    glUniform4fv location, 1, data.caddr

proc `[]=`*(s: Shader; key: string; value: Color) =
    var location = s.getKeyLocation key
    var data = vec4(value.r, value.g, value.b, value.a)
    glUniform4fv location, 1, data.caddr

proc `[]=`*(s: Shader; key: string; value: float32) =
    var location = s.getKeyLocation key
    glUniform1f location, value


proc `[]=`*(s: Shader; key: string; value: int) =
    var location = s.getKeyLocation key
    glUniform1i location, value.GLint


proc `[]=`*(s: Shader; key: string; value: var Mat4) =
    var location = s.getKeyLocation key
    glUniformMatrix4fv location, 1, false, value.caddr

proc `[]=`*(s: Shader; key: string; value: ptr Mat4) =
    var location = s.getKeyLocation key
    glUniformMatrix4fv location, 1, false, value[].caddr

proc `[]=`*(s: Shader; key: string; value: Mat4) =
    var matrix = value
    s[key] = matrix

method update(p: ShaderParam, shader: Shader) {.base.} = discard
method update(p: ShaderParamInt, shader: Shader) = shader[p.key] = p.value
method update(p: ShaderParamFloat, shader: Shader) = shader[p.key] = p.value
method update(p: ShaderParamVec2, shader: Shader) = shader[p.key] = p.value
method update(p: ShaderParamVec3, shader: Shader) = shader[p.key] = p.value
method update(p: ShaderParamVec4, shader: Shader) = shader[p.key] = p.value
method update(p: ShaderParamMat4, shader: Shader) = shader[p.key] = p.value
method update(p: ShaderParamTexture, shader: Shader) = use(p.value, p.slot)

proc set*(shader: Shader, key: string, value: int32) =
    let param = new(ShaderParamInt)
    param.key = key
    param.value = value
    shader.params[key] = param

proc set*(shader: Shader, key: string, value: int) = set(shader, key, value.int32)

proc get_int*(shader: Shader, key: string): int32 =
    let param = shader.params[key]
    result = cast[ShaderParamInt](param).value

proc set*(shader: Shader, key: string, value: float32) =
    let param = new(ShaderParamFloat)
    param.key = key
    param.value = value
    shader.params[key] = param

proc get_float*(shader: Shader, key: string): float32 =
    let param = shader.params[key]
    result = cast[ShaderParamFloat](param).value

proc set*(shader: Shader, key: string, value: Vec2) =
    let param = new(ShaderParamVec2)
    param.key = key
    param.value = value
    shader.params[key] = param

proc get_vec2*(shader: Shader, key: string): Vec2 =
    let param = shader.params[key]
    result = cast[ShaderParamVec2](param).value

proc set*(shader: Shader, key: string, value: Vec3) =
    let param = new(ShaderParamVec3)
    param.key = key
    param.value = value
    shader.params[key] = param

proc get_vec3*(shader: Shader, key: string): Vec3 =
    let param = shader.params[key]
    result = cast[ShaderParamVec3](param).value

proc set*(shader: Shader, key: string, value: Vec4) =
    let param = new(ShaderParamVec4)
    param.key = key
    param.value = value
    shader.params[key] = param

proc get_vec4*(shader: Shader, key: string): Vec4 =
    let param = shader.params[key]
    result = cast[ShaderParamVec4](param).value

proc set*(shader: Shader, key: string, value: Mat4) =
    let param = new(ShaderParamMat4)
    param.key = key
    param.value = value
    shader.params[key] = param

proc get_mat4*(shader: Shader, key: string): Mat4 =
    let param = shader.params[key]
    result = cast[ShaderParamMat4](param).value

proc set*(shader: Shader, key: string, value: Texture, slot: int) =
    let param = new(ShaderParamTexture)
    param.key = key
    param.value = value
    param.slot = slot
    shader.params[key] = param


proc use*(shader: Shader) =
    glUseProgram(shader.program)
    for param in values(shader.params):
        update(param, shader)

proc destroy*(shader: Shader) = remove(cache, shader)
proc cleanupShaders*() =
    echo &"Cleaning up [{len(cache)}] shaders..."
    clear(cache)

proc newSpatialShader*(vertexSource: string="", fragmentSource: string=""): Shader =
    var 
        vsource: string
        fsource = forwardF.replace("$MAX_LIGHTS$", &"{settings.maxLights}")
            
    if isEmptyOrWhitespace(fragmentSource):
        fsource = fsource
            .replace("$MAIN_FUNCTION$", "")
            .replace("$MAIN_FUNCTION_CALL$", "")
    else:
        fsource = fsource
            .replace("$MAIN_FUNCTION$", fragmentSource)
            .replace("$MAIN_FUNCTION_CALL$", "fragment();")

    if isEmptyOrWhitespace(vertexSource):
        vsource = forwardV
            .replace("$MAIN_FUNCTION$", "")
            .replace("$MAIN_FUNCTION_CALL$", "")
    else:
        vsource = forwardV
            .replace("$MAIN_FUNCTION$", vertexSource)
            .replace("$MAIN_FUNCTION_CALL$", "vertex();")

    result = newShader(vsource, fsource, [])

proc newCanvasShader*(vertexSource, fragmentSource: string): Shader =
    var fsource, vsource: string
    if isEmptyOrWhitespace(fragmentSource):
        fsource = forwardPostF
            .replace("$MAIN_FUNCTION$", "")
            .replace("$MAIN_FUNCTION_CALL$", "")
    else:
        fsource = forwardPostF
            .replace("$MAIN_FUNCTION$", fragmentSource)
            .replace("$MAIN_FUNCTION_CALL$", "fragment();")

    if isEmptyOrWhitespace(vertexSource):
        vsource = forwardPostV
            .replace("$MAIN_FUNCTION$", "")
            .replace("$MAIN_FUNCTION_CALL$", "")
    else:
        vsource = forwardPostV
            .replace("$MAIN_FUNCTION$", vertexSource)
            .replace("$MAIN_FUNCTION_CALL$", "vertex();")

    result = newShader(vsource, fsource, [])

proc newCanvasShader*(source: string=""): Shader = newCanvasShader(vertexSource="", fragmentSource=source)
