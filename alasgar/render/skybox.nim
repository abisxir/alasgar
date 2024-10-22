import ../ports/opengl
import ../texture
import ../utils
import ../shaders/base
import ../shaders/compile
import ../shaders/skybox

type
    Skybox* = ref object
        cubeVAO: GLuint
        cubeVBO: GLuint
        shader: Shader

var vertices = [
    #
    -1'f32,  1'f32, -1'f32,
    -1'f32, -1'f32, -1'f32,
     1'f32, -1'f32, -1'f32,
     1'f32, -1'f32, -1'f32,
     1'f32,  1'f32, -1'f32,
    -1'f32,  1'f32, -1'f32,
    #
    -1'f32, -1'f32,  1'f32,
    -1'f32, -1'f32, -1'f32,
    -1'f32,  1'f32, -1'f32,
    -1'f32,  1'f32, -1'f32,
    -1'f32,  1'f32,  1'f32,
    -1'f32, -1'f32,  1'f32,
    #
     1'f32, -1'f32, -1'f32,
     1'f32, -1'f32,  1'f32,
     1'f32,  1'f32,  1'f32,
     1'f32,  1'f32,  1'f32,
     1'f32,  1'f32, -1'f32,
     1'f32, -1'f32, -1'f32,
    #
    -1'f32, -1'f32,  1'f32,
    -1'f32,  1'f32,  1'f32,
     1'f32,  1'f32,  1'f32,
     1'f32,  1'f32,  1'f32,
     1'f32, -1'f32,  1'f32,
    -1'f32, -1'f32,  1'f32,
    #
    -1'f32,  1'f32, -1'f32,
     1'f32,  1'f32, -1'f32,
     1'f32,  1'f32,  1'f32,
     1'f32,  1'f32,  1'f32,
    -1'f32,  1'f32,  1'f32,
    -1'f32,  1'f32, -1'f32,

    -1'f32, -1'f32, -1'f32,
    -1'f32, -1'f32,  1'f32,
     1'f32, -1'f32, -1'f32,
     1'f32, -1'f32, -1'f32,
    -1'f32, -1'f32,  1'f32,
     1'f32, -1'f32,  1'f32
]

proc newSkybox*(): Skybox =
    new(result)
    result.shader = newSpatialShader(skyboxVertex, skyboxFragment)
    glGenVertexArrays(1, addr(result.cubeVAO))
    glBindVertexArray(result.cubeVAO)
    glGenBuffers(1, addr(result.cubeVBO))
    glBindBuffer(GL_ARRAY_BUFFER, result.cubeVBO)
    glBufferData(GL_ARRAY_BUFFER, (sizeof(float32) * vertices.len).GLsizeiptr, addr(vertices[0]), GL_STATIC_DRAW)
    glVertexAttribPointer(0, 3, cGL_FLOAT, false, (3 * sizeof(float32)).GLsizei, cast[pointer](0))
    glEnableVertexAttribArray(0)

    glBindVertexArray(0)
    glBindBuffer(GL_ARRAY_BUFFER, 0)

proc destroy*(skybox: Skybox) =
    if skybox != nil:
        if skybox.cubeVBO != 0:
            glDeleteBuffers(1, addr(skybox.cubeVBO))
            skybox.cubeVBO = 0
        if skybox.cubeVAO != 0:
            glDeleteVertexArrays(1, addr(skybox.cubeVAO))
            skybox.cubeVAO = 0

proc render*(skybox: Skybox, cubemap: Texture, view, projection: Mat4, intensity, blurrity: float32) = 
    var normalizedView = view
    normalizedView.m30 = 0
    normalizedView.m31 = 0
    normalizedView.m32 = 0

    use(skybox.shader)
    skybox.shader["VIEW"] = normalizedView
    skybox.shader["PROJECTION"] = projection
    skybox.shader["ENVIRONMENT_INTENSITY"] = intensity
    skybox.shader["ENVIRONMENT_BLURRITY"] = blurrity
    skybox.shader["MIP_COUNT"] = cubemap.levels.float32
    use(skybox.shader, cubemap, "SKYBOX_MAP", 0)

    glDepthMask(GL_FALSE.GLboolean)
    glBindVertexArray(skybox.cubeVAO)
    
    glDrawArrays(GL_TRIANGLES, 0, 36)
    
    glBindVertexArray(0)
    glDepthMask(GL_TRUE.GLboolean)
