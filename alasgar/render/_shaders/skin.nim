import types

proc sampleSkin(map: Sampler2D, env: Environment, offset: int): Vec4 =
    let 
        y = offset div env.SKIN_SAMPLER_WIDTH
        x = offset mod env.SKIN_SAMPLER_WIDTH
        P = ivec2(x, y)
    return texelFetch(map, P, 0).rgba


proc getBoneTransform(map: Sampler2D, env: Environment, skin: Vec4, index: float): Mat4 =
    # Calculate the texel coordinates for the matrix data, taking into account the offset
    let start = int(skin[1]) + int(index) * 4
    return mat4(
        sampleSkin(map, env, start),
        sampleSkin(map, env, start + 1),
        sampleSkin(map, env, start + 2),
        sampleSkin(map, env, start + 3)
    )

proc applySkinTransform*(map: Sampler2D, 
                        env: Environment,
                        model: Mat4,
                        bone, weight, skin: Vec4): Mat4 =
    result = model
    if skin[0] > 0.0:
        result = 
            getBoneTransform(map, env, skin, bone[0]) * weight[0] +
            getBoneTransform(map, env, skin, bone[1]) * weight[1] +
            getBoneTransform(map, env, skin, bone[2]) * weight[2] +
            getBoneTransform(map, env, skin, bone[3]) * weight[3]
