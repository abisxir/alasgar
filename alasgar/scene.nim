import core
import utils
import shaders/base
import texture
import render/fb
import render/gpu
import shaders/ibl
import shaders/compile


# Forward declarations
#proc generateGGX(cubemap: Texture, sampleCount: int): Texture

func calculateMipMap(size: int): int = log2(size.float32).int + 1

proc panoramaToCubemap(inTexture: Texture, size: int): Texture =
    let 
        fb = newFramebuffer()
        shader = newCanvasShader(panoramaToCubemapFragment)
        texture = newCubeTexture(
            size,
            size,
            minFilter=GL_NEAREST_MIPMAP_LINEAR,
            magFilter=GL_LINEAR,
            levels=calculateMipMap(size)
        )
    
    use(shader)
    for i in 0..5:
        use(fb, texture, GL_TEXTURE_CUBE_MAP_POSITIVE_X.int + i, 0, size, size)
        use(shader, inTexture, "PANAROMA_MAP", 0)
        shader["FACE"] = i
        draw(fb)
    
    mipmap(texture)
    destroy(shader)
    destroy(fb)

    return texture

## Sets the given cubemap texture as skybox
proc setSkybox*(scene: Scene, cubemap: Texture) =
    scene.environmentMap = cubemap
    #scene.ggxMap = generateGGX(cubemap, setting.envSampleCount)
    #scene.lutMap = generateLUT(cubemap, setting.envSampleCount)    

template `skybox=`*(scene: Scene, cubemap: Texture) = setSkybox(scene, cubemap)

## Loads the given six images and sets it as skybox
proc setSkybox*(scene: Scene, px, nx, py, ny, pz, nz: string) = 
    scene.skybox = newCubeTexture(
        px, 
        nx, 
        py, 
        ny, 
        pz, 
        nz
    )

## Loads the given panaroma image and sets it as skybox
proc setSkybox*(scene: Scene, url: string, size: int) = 
    # Loads the given panaroma into a texture
    let inTexture = newTexture(url)
    # Converts panaroma texture to cubemap and sets it as skybox
    scene.skybox = panoramaToCubemap(inTexture, size)
    # Destroys the created texture
    destroy(inTexture)


#[
proc filter(cubemap: Texture, 
            fb: FrameBuffer,
            target: Texture,
            level: int,
            distribution: int,
            sampleCount: int,
            lodBias: float32) =
    let 
        shader = newCanvasShader(iblFilterFS)
        roughness = level.float32 / (target.levels.float32 - 1.0)
        size = cubemap.width
        currentTextureSize = size shr level
    
    for i in 0..5:
        use(fb, target, GL_TEXTURE_CUBE_MAP_POSITIVE_X.int + i, level, currentTextureSize, currentTextureSize)       
        use(shader)
        use(shader, cubemap, "u_cubemap", 0)

        shader["u_roughness"] = roughness
        shader["u_sample_count"] = sampleCount
        shader["u_width"] = size
        shader["u_lod_bias"] = lodBias
        shader["u_distribution"] = distribution
        shader["u_current_face"] = i
        shader["u_is_generating_lut"] = 0.int

        draw(fb)

    destroy(shader)


proc generateGGX(cubemap: Texture, sampleCount: int): Texture =
    let 
        fb = newFramebuffer()
        size: int = cubemap.width
        texture = newCubeTexture(
            size, 
            size, 
            minFilter=GL_LINEAR, 
            magFilter=GL_LINEAR, 
            levels=calculateMipMap(size)
        )

    mipmap(texture)

    for level in 0..texture.levels - 1:
        filter(
            cubemap=cubemap, 
            fb=fb, 
            target=texture, 
            level=level, 
            distribution=1, 
            sampleCount=sampleCount, 
            lodBias=0.0
        )

    destroy(fb)

    result = texture

proc generateLUT(cubemap: Texture, sampleCount: int): Texture =
    let 
        shader = newShader(fullscreenVS, iblFilterFS, [])
        fb = newFramebuffer()
        texture = newTexture2D(
            cubemap.width, 
            cubemap.height,
            minFilter=GL_LINEAR, 
            magFilter=GL_LINEAR,
            levels=1
        )

    allocate(texture)
    use(fb, texture, GL_TEXTURE_2D.int, 0, cubemap.width, cubemap.height)
    use(shader)
    use(shader, cubemap, "u_cubemap", 0)

    shader["u_roughness"] = 0.0
    shader["u_sample_count"] = sampleCount
    shader["u_width"] = 0
    shader["u_lod_bias"] = 0.0
    shader["u_distribution"] = 1
    shader["u_current_face"] = 0
    shader["u_is_generating_lut"] = 1.int

    draw(fb)

    destroy(shader)
    destroy(fb)

    result = texture

]#