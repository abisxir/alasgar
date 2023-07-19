import algorithm
import hashes
#import threadpool
#{.experimental: "parallel".}

import ../core
import ../system
import ../render/gpu
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
    if result == 0:
        if a.castShadow and not b.castShadow:
            result = -1
        elif not a.castShadow and b.castShadow:
            result = 1

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
            drawable.materialPack[0] = packUnorm4x8(0.7, 0.7, 0.7, 1)
            drawable.materialPack[1] = packUnorm4x8(0.7, 0.7, 0.7, 0)
            drawable.materialPack[2] = packUnorm4x8(0.1, 0.1, 0.1, 0)
            drawable.materialPack[3] = packUnorm4x8(0, 0, 0.3, 0)
            drawable.spritePack = vec4(0, 0, 0, 0)
    else:
        let material = drawable.material
        if drawable.materialVersion != drawable.material.version:
            drawable.materialVersion = material.version
            drawable.materialPack[0] = packUnorm4x8(material.diffuseColor.r, material.diffuseColor.g, material.diffuseColor.b, material.diffuseColor.a)
            drawable.materialPack[1] = packUnorm4x8(material.specularColor.r, material.specularColor.g, material.specularColor.b, material.uvChannels.float32 / 63.float32)
            drawable.materialPack[2] = packUnorm4x8(material.emissiveColor.r, material.emissiveColor.g, material.emissiveColor.b, material.availableMaps.float32 / 63.float32)
            drawable.materialPack[3] = packUnorm4x8(material.metallic, material.roughness, material.reflectance, material.ao)
            drawable.spritePack = vec4(material.frameSize.x, material.frameSize.y, material.frameOffset.x, material.frameOffset.y) 
        #if material.albedoMap != nil and drawable.mesh.version != drawable.meshVersion and drawable.mesh of SpriteComponent:
        #    drawable.meshVersion = drawable.mesh.version
    if drawable.skin != nil:
        drawable.skinPack = vec4(drawable.skin.count.float32, drawable.skin.offset.float32, 0, 0)
    else:
        drawable.skinPack = vec4(0, 0, 0, 0)

func getNormalHash(d: ptr Drawable): Hash =
    result = 0
    if d.material != nil and d.material.normalMap != nil:
        result = hash(d.material.normalMap)

func getTextureHash(d: ptr Drawable): Hash =
    result = 0
    if d.material != nil and d.material.albedoMap != nil:
        result = hash(d.material.albedoMap)

method process*(sys: PrepareSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) =
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
                addShader(graphics.context, drawable.shader.instance)

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


                
                


