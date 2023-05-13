import types

proc shadowVertex*(iPosition: Layout[0, Vec3], 
                   iNormal: Layout[1, Vec3],
                   iUV: Layout[2, Vec4],
                   iBone: Layout[3, Vec4], 
                   iWeight: Layout[4, Vec4],
                   iModel: Layout[5, Mat4],
                   iMaterial: Layout[9, UVec4],
                   iSprite: Layout[10, Vec4],
                   iSkin: Layout[11, Vec4],
                   SHADOW_MVP: Uniform[Mat4],
                   DEPTH: var float,
                   gl_Position: var Vec4) =
    let 
        fragmentPosition = iModel * vec4(iPosition, 1.0)
        lightPosition = SHADOW_MVP * fragmentPosition
        nz = lightPosition.z / lightPosition.w;
    DEPTH = 0.5 + (nz * 0.5)
    gl_Position = lightPosition


proc shadowFragment*(DEPTH: float,
                     DATA: var Layout[0, Vec2]) =
    let 
        dx: float = dFdx(DEPTH)  
        dy: float = dFdy(DEPTH)   
        y: float = DEPTH * DEPTH + 0.25 * (dx * dx + dy * dy)   
    DATA = vec2(DEPTH, y)
