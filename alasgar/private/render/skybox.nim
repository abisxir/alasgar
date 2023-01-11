import ../ports/opengl
import ../texture
import ../utils
import ../shader

const forwardSkyboxV = staticRead("shaders/forward-skybox-cube.vs")
const forwardSkyboxF = staticRead("shaders/forward-skybox-cube.fs")

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
    result.shader = newShader(forwardSkyboxV, forwardSkyboxF, [])
    glGenVertexArrays(1, addr(result.cubeVAO))
    glGenBuffers(1, addr(result.cubeVAO))
    glBindVertexArray(result.cubeVAO);
    glBindBuffer(GL_ARRAY_BUFFER, result.cubeVAO);
    glBufferData(GL_ARRAY_BUFFER, (sizeof(vertices)).GLsizeiptr, addr(vertices[0]), GL_STATIC_DRAW);
    glEnableVertexAttribArray(0)
    glVertexAttribPointer(0, 3, cGL_FLOAT, false, (3 * sizeof(float32)).GLsizei, cast[pointer](0))

proc destroy*(skybox: Skybox) =
    if skybox != nil:
        if skybox.cubeVBO != 0:
            glDeleteBuffers(1, addr(skybox.cubeVBO))
            skybox.cubeVBO = 0
        if skybox.cubeVAO != 0:
            glDeleteVertexArrays(1, addr(skybox.cubeVAO))
            skybox.cubeVAO = 0

proc render*(skybox: Skybox, cubemap: Texture, view, projection: Mat4, intensity: float32) = 
    use(skybox.shader)
    var normalizedView = view
    normalizedView[12] = 0
    normalizedView[13] = 0
    normalizedView[14] = 0
    skybox.shader["u_view"] = normalizedView
    skybox.shader["u_projection"] = projection
    skybox.shader["u_environment_intensity"] = intensity
    skybox.shader["u_mip_count"] = cubemap.levels.float32

    glDepthMask(GL_FALSE.GLboolean)
    use(cubemap, 0)
    glBindVertexArray(skybox.cubeVAO)
    glDrawArrays(GL_TRIANGLES, 0, 36)
    glBindVertexArray(0)
    glDepthMask(GL_TRUE.GLboolean)
