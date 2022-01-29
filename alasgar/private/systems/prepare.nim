import algorithm
import hashes
#import threadpool
#{.experimental: "parallel".}

import ../core
import ../system
import ../render/graphic
import ../components/line
import ../components/sprite
#import ../components/camera
import ../physics/plane


type
    PrepareSystem* = ref object of System

proc newPrepareSystem*(): PrepareSystem =
    new(result)
    result.name = "Prepare System"

func cmp(a, b: MaterialComponent): int =
    if a == b:
        result = 0
    elif a == nil:
        if b.albedoMap == nil and b.normalMap == nil:
            result = 0
        else:
            result = -1
    elif b == nil:
        if a.albedoMap == nil and a.normalMap == nil:
            result = 0
        else:
            result = 1
    else:
        if a.albedoMap == b.albedoMap:
            if a.normalMap == b.normalMap:
                result = 0
            else:
                result = cmp(a.normalMap, b.normalMap)
        else:
            result = cmp(a.albedoMap, b.albedoMap)

proc cmp(a, b: Drawable): int =
    if a.visible != b.visible:
        if a.visible:
            return -1
        return 1
    if not a.visible:
        return 0
    if a.shader == b.shader:
        if a.material == b.material:
            if a.mesh.instance == b.mesh.instance:
                if a.transform.globalPosition.z > b.transform.globalPosition.z:
                    return 1
                elif a.transform.globalPosition.z < b.transform.globalPosition.z:
                    return -1
                else:
                    return 0
            return cmp(a.mesh.instance, b.mesh.instance)
        return cmp(a.material, b.material)
    return cmp(a.shader, b.shader)


proc isInSight*(planes: openArray[Plane], drawable: Drawable): bool =
    #drawable.mesh.instance.
    let center = drawable.transform.globalPosition
    let diameter = drawable.mesh.instance.vRadius * 2
    for p in planes:
        if distanceTo(p, center) + diameter > 0:
            return true
    return false 

proc isInSight*(viewCenter: Vec3, viewRadiusSqrt: float32, drawable: Drawable): bool =
    let meshCenter = drawable.transform.globalPosition
    let meshRadius = drawable.mesh.instance.vRadius
    return lengthSq(meshCenter - viewCenter) - (meshRadius * meshRadius) < viewRadiusSqrt

proc packMaterial*(drawable: ptr Drawable) =
    # Handle material
    if drawable.material == nil:
        if drawable.materialVersion != 0: 
            drawable.materialVersion = 0
            drawable.materialPack[0] = packUnorm4x8(1, 1, 1, 1)
            drawable.materialPack[1] = packUnorm4x8(1, 1, 1, 1)
            drawable.materialPack[2] = packUnorm4x8(1.0, 1.0, 0.1, 1.0)
            drawable.materialPack[3] = 0
            drawable.spritePack = vec4(0, 0, 0, 0)
    else:
        let material = drawable.material
        if drawable.materialVersion != drawable.material.version:
            drawable.materialVersion = material.version
            drawable.materialPack[0] = packUnorm4x8(material.baseColor.r, material.baseColor.g, material.baseColor.b, material.entity.opacity)
            drawable.materialPack[1] = packUnorm4x8(material.emmisiveColor.r, material.emmisiveColor.g, material.emmisiveColor.b, material.emmisiveColor.a)
            drawable.materialPack[2] = packUnorm4x8(material.metallic, material.roughness, material.reflectance, material.ao)
            drawable.materialPack[3] = material.availableMaps
            drawable.spritePack = vec4(material.frameSize.x, material.frameSize.y, material.frameOffset.x, material.frameOffset.y) 

        if material.albedoMap != nil and drawable.mesh.version != drawable.meshVersion and drawable.mesh of SpriteComponent:
            drawable.meshVersion = drawable.mesh.version
            #drawable.extra[6] = packSnorm2x16(material.albedoMap.ratio)

func getNormalHash(d: ptr Drawable): Hash =
    result = 0
    if d.material != nil and d.material.normalMap != nil:
        result = hash(d.material.normalMap)

func getTextureHash(d: ptr Drawable): Hash =
    result = 0
    if d.material != nil and d.material.albedoMap != nil:
        result = hash(d.material.albedoMap)

method process*(sys: PrepareSystem, scene: Scene, input: Input, delta: float32, frames: float32, age: float32) =
    if scene.root != nil:
        # Considers all the lines
        for c in iterateComponents[LineComponent](scene):
            if c.entity.visible:
                updatePoints(c)

        # Marks invisible items
        for drawable in mitems(scene.drawables):
            drawable.visible =
                drawable.transform.entity.visible and drawable.transform.entity.attached and drawable.transform.entity.opacity > 0

        # Sorts using the custom compare function
        sort(scene.drawables, cmp)

        var lastMeshHash = 0
        var lastNormalHash = 0
        var lastTextureHash = 0
        var count = 0'i32
        for i in countdown(high(scene.drawables), low(scene.drawables)):
            var drawable = addr(scene.drawables[i])

            if not drawable.visible:
                continue

            # Adds shader to graphic
            if drawable.shader != nil:
                addShader(sys.graphic, drawable.shader.instance)

            # Checks mesh hash for counting
            let meshHash = hash(drawable.mesh.instance)
            let normalHash = getNormalHash(drawable)
            let textureHash = getTextureHash(drawable)
            if lastMeshHash != meshHash or lastNormalHash != normalHash or lastTextureHash != textureHash:
                count = 1
                lastMeshHash = meshHash
                lastTextureHash = textureHash
                lastNormalHash = normalHash
            else:
                count += 1
            drawable.count = count

            # Handle transfer
            if drawable.transformVersion != drawable.transform.version:
                drawable.transformVersion = drawable.transform.version
                drawable.modelPack = drawable.transform.world

            # Handle material
            packMaterial(drawable)


                
                


