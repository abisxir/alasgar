import ../utils
import ../system
import ../core
import ../shaders/base
import ../texture
import ../render/gpu

type
    JointSystem* = ref object of System
    SkinSystem* = ref object of System
        buffer: seq[float32]

proc newJointComponent*(skin: SkinComponent, inverseMatrix: Mat4): JointComponent =
    new(result)
    result.inverseMatrix = inverseMatrix
    add(skin.joints, result)

proc newSkinComponent*(): SkinComponent =
    new(result)

# Joint system implementation
proc newJointSystem*(): JointSystem = 
    new(result)
    result.name = "Joint"

method process*(sys: JointSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) = 
    for joint in iterate[JointComponent](scene):
        if joint.entity.visible:
            joint.model = joint.transform.world * joint.inverseMatrix

# Skin system implementation
proc newSkinSystem*(): SkinSystem = 
    new(result)
    result.name = "Skin"
    setLen(result.buffer, 4 * settings.maxSkinTextureSize * settings.maxSkinTextureSize)

proc copy(skin: SkinComponent, buffer: var seq[float32], offset: var int) =
    const size = 16 * sizeof(float32)
    for joint in skin.joints:
        copyMem(buffer[offset].addr, joint.model.caddr, size)
        inc(offset, 16)

method process*(sys: SkinSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) = 
    {.warning[LockLevel]:off.}
    var 
        offset = 0
        capacity = settings.maxSkinTextureSize * settings.maxSkinTextureSize
    for skin in iterate[SkinComponent](scene):
        if skin.entity.visible:
            let size = len(skin.joints) * 16
            if offset + size >= capacity:
                # Does not continue as buffer is full
                break
            skin.offset = offset div 4
            skin.count = len(skin.joints)
            skin.texture = graphics.skinTexture
            copy(skin, sys.buffer, offset)


    if offset > 0:
        attach(graphics.skinTexture)
        copy(graphics.skinTexture, sys.buffer[0].addr, width=settings.maxSkinTextureSize, height=offset div settings.maxSkinTextureSize)
                    
        
