import hashes
import strformat
import tables
import ports/opengl

import utils


type
    ShaderObject* = object
        program*: GLuint
        map: Table[string, GLint]

    Shader* = ref ShaderObject


proc `=destroy`*(shader: var ShaderObject) =
    if shader.program != 0:
        glDeleteProgram(shader.program)
        shader.program = 0


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
        logi "Shader compile error: ", info
        logi "The shader: ", src
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
        glBindAttribLocation(result, a.index, a.name)

    glLinkProgram(result)
    glDeleteShader(vShader)
    glDeleteShader(fShader)

    let linked = isProgramLinked(result)
    if not linked:
        halt &"Could not link: {programInfoLog(result)}"


proc newShader*(vs, fs: string, attributes: openarray[tuple[index: GLuint, name: string]]): Shader =
    new(result)
    result.program = createProgram(vs, fs, attributes)


proc destroy*(shader: Shader) =
    if shader.program != 0:
        glDeleteProgram(shader.program)
        shader.program = 0


proc use*(s: Shader) =
    glUseProgram(s.program)


proc getKeyLocation(s: Shader, key: string): GLint =
    if not s.map.hasKey(key):
        s.map[key] = glGetUniformLocation(s.program, key)
    result = s.map[key]


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
    var location = s.getKeyLocation key
    var matrix = value
    glUniformMatrix4fv location, 1, false, matrix.caddr
