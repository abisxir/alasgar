import common

proc uvToXYZ(FACE: int, UV: Vec2): Vec3 =
    if FACE == 0:
        result = vec3(1.0, UV.y, -UV.x)
    elif FACE == 1:
        result = vec3(-1.0, UV.y, UV.x)
    elif FACE == 2:
        result = vec3(UV.x, -1.0, UV.y)
    elif FACE == 3:
        result = vec3(UV.x, 1.0, -UV.y)
    elif FACE == 4:
        result = vec3(UV.x, UV.y, 1.0)
    else:
        result = vec3(-UV.x, UV.y, -1.0)

proc dirToUV(dir: Vec3): Vec2 = 
    let 
        x: float = 0.5 + 0.5 * atan(dir.z, dir.x) / PI
        y: float = 1.0 - acos(dir.y) / PI
    result = vec2(x, y)

proc panoramaToCubemapFragment*(UV: Vec2,
                                FACE: Uniform[int],
                                PANAROMA_MAP: Layout[0, Uniform[Sampler2D]],
                                COLOR: var Vec4) =
    let 
        texCoordNew = UV * 2.0 - 1.0
        scan = uvToXYZ(FACE, texCoordNew)
        direction: Vec3 = normalize(scan)
        src = dirToUV(direction)
    COLOR.rgb = texture(PANAROMA_MAP, src).rgb
    COLOR.a = 1.0