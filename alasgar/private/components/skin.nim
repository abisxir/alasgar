import ../utils
import ../system
import ../core
import ../shader
import ../texture

type
    JointSystem* = ref object of System
    SkinSystem* = ref object of System
        texture: Texture
        buffer: seq[float32]
        width, height: int

proc newJointComponent*(skin: SkinComponent, inverseMatrix: Mat4): JointComponent =
    new(result)
    result.inverseMatrix = inverseMatrix
    add(skin.joints, result)

proc newSkinComponent*(): SkinComponent =
    new(result)

# Joint system implementation
proc newJointSystem*(): JointSystem = 
    new(result)
    result.name = "Joint System"

method process*(sys: JointSystem, scene: Scene, input: Input, delta: float32, frames: float32, age: float32) = 
    for joint in iterateComponents[JointComponent](scene):
        if joint.entity.visible:
            joint.model = joint.transform.world * joint.inverseMatrix

# Skin system implementation
proc newSkinSystem*(): SkinSystem = 
    new(result)
    # TODO: get a proper size for it.
    result.name = "Skin System"
    result.width = 2048
    result.height = 2048
    setLen(result.buffer, 4 * result.width * result.height)
    result.texture = newTexture2D(result.width, result.height, internalFormat=GL_RGBA32F)
    allocate(result.texture)

proc copy(skin: SkinComponent, buffer: var seq[float32], offset: var int) =
    const size = 16 * sizeof(float32)
    for joint in skin.joints:
        copyMem(buffer[offset].addr, joint.model.caddr, size)
        inc(offset, 16)

method process*(sys: SkinSystem, scene: Scene, input: Input, delta: float32, frames: float32, age: float32) = 
    var 
        offset = 0
        capacity = sys.width * sys.height
    for skin in iterateComponents[SkinComponent](scene):
        if skin.entity.visible:
            let size = len(skin.joints) * 16
            if offset + size < capacity:
                skin.offset = offset div 4
                skin.count = len(skin.joints)
                skin.texture = sys.texture
                copy(skin, sys.buffer, offset)
                #var f = open(&"/tmp/skin.data.{skin.offset}", fmWrite)
                #for v in skin.offset..<skin.offset + skin.count * 16:
                #    writeLine(f, &"{sys.buffer[v]}")
                #close(f)

    if offset > 0:
        attach(sys.texture)
        var height = offset div sys.width + 1
        if height > sys.height:
            height = sys.height
        copy(sys.texture, sys.buffer[0].addr, width=sys.width, height=offset div sys.width)

        # Attachs skin texture to all of shaders
        for shader in sys.graphic.context.shaders:
            use(shader)
            use(sys.texture, 15)
            shader["env.skin_sampler_width"] = sys.width

            
method cleanup(sys: SkinSystem) =
    destroy(sys.texture)
        
        
