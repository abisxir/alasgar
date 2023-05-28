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
    Shader* = ref object
        program*: GLuint
        map: Table[string, GLint]
        params: Table[string, ShaderParam]
        source: string

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
    ShaderParamColor* = ref object of ShaderParam
        value: Color
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


proc createProgram*(vs, fs: string,
        attributes: openarray[tuple[index: int, name: string]]): GLuint =
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
        glBindAttribLocation(result, a.index.GLuint, a.name.cstring)

    glLinkProgram(result)
    glDeleteShader(vShader)
    glDeleteShader(fShader)

    let linked = isProgramLinked(result)
    if not linked:
        echo(vs)
        echo(fs)
        halt &"Could not link: {programInfoLog(result)}"


proc newShader*(vs, fs: string, attributes: openarray[tuple[index: int, name: string]]): Shader =
    new(result)
    let shaderProfile = &"#version {OPENGL_SHADER_VERSION}"
    
    result.program = createProgram(
        vs.replace("$SHADER_PROFILE$", shaderProfile), 
        fs.replace("$SHADER_PROFILE$", shaderProfile), attributes)
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


proc `[]=`*(s: Shader; key: string; value: var Mat4) =
    var location = getUniformLocation(s, key)
    glUniformMatrix4fv location, 1, false, value.caddr

proc `[]=`*(s: Shader; key: string; value: ptr Mat4) =
    var location = getUniformLocation(s, key)
    glUniformMatrix4fv location, 1, false, value[].caddr

proc `[]=`*(s: Shader, key: string, value: Mat4) =
    var matrix = value
    s[key] = matrix

#proc `[]`*(s: Shader, key: string): int = getUniformLocation(s, key).int

method update(p: ShaderParam, shader: Shader) {.base.} = discard
method update(p: ShaderParamInt, shader: Shader) = shader[p.key] = p.value
method update(p: ShaderParamFloat, shader: Shader) = shader[p.key] = p.value
method update(p: ShaderParamVec2, shader: Shader) = shader[p.key] = p.value
method update(p: ShaderParamVec3, shader: Shader) = shader[p.key] = p.value
method update(p: ShaderParamVec4, shader: Shader) = shader[p.key] = p.value
method update(p: ShaderParamColor, shader: Shader) = shader[p.key] = p.value
method update(p: ShaderParamMat4, shader: Shader) = shader[p.key] = p.value
method update(p: ShaderParamTexture, shader: Shader) = 
    shader[p.key] = p.slot
    unit(p.value, p.slot)

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

proc set*(shader: Shader, key: string, value: Color) =
    let param = new(ShaderParamColor)
    param.key = key
    param.value = value
    shader.params[key] = param

proc get_color*(shader: Shader, key: string): Color =
    let param = shader.params[key]
    result = cast[ShaderParamColor](param).value

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

proc use*(shader: Shader, texture: Texture, name: string, slot: int) =
    var location = getUniformLocation(shader, name)
    if location >= 0:
        #echo &"Setting [{name}] to [{slot}] in location [{location.int}]" 
        shader[name] = slot
        unit(texture, slot)

proc destroy*(shader: Shader) = remove(cache, shader)
proc cleanupShaders*() =
    echo &"Cleaning up [{len(cache)}] shaders..."
    clear(cache)

proc newSpatialShader*(vertexSource: string="", fragmentSource: string=""): Shader = newShader(toGLSL(mainVertex), toGLSL(mainFragment), [])
proc newCanvasShader*(vertexSource: string="", fragmentSource: string=""): Shader = newShader(toGLSL(effectVertex), toGLSL(effectFragment), [])
