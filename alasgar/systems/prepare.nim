import algorithm
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
    result.name = "Prepare"

func cmp(a, b: Drawable): int = cmp(a.id, b.id)

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

method process*(sys: PrepareSystem, scene: Scene, input: Input, delta: float32, frames: int, age: float32) =
    if scene.root != nil:
        # Considers all the lines
        for c in iterate[LineComponent](scene):
            if c.entity.visible:
                updatePoints(c)

        # Marks invisible items
        for drawable in mitems(scene.drawables):
            drawable.visible =
                drawable.transform.entity.visible and drawable.transform.entity.attached and drawable.transform.entity.opacity > 0

        # Sorts using the custom compare function
        sort(scene.drawables, cmp)

        var 
            lastId: string
            count = 0'i32
        for i in countdown(high(scene.drawables), low(scene.drawables)):
            var drawable = addr(scene.drawables[i])

            if not drawable.visible:
                continue

            # Adds shader to graphic
            if drawable.shader != nil:
                addShader(graphics.context, drawable.shader.instance)

            if lastId != drawable.id or count > settings.maxBatchSize:
                count = 1
                lastId = drawable.id
            else:
                count += 1
            
            drawable.count = count

            # Handle transfer
            if drawable.transformVersion != drawable.transform.version:
                drawable.transformVersion = drawable.transform.version
                drawable.modelPack = drawable.transform.world

            # Handle material
            packMaterial(drawable)
