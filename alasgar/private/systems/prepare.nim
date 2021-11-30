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
        if b.texture == nil and b.normal == nil:
            result = 0
        else:
            result = -1
    elif b == nil:
        if a.texture == nil and a.normal == nil:
            result = 0
        else:
            result = 1
    else:
        if a.texture == b.texture:
            if a.normal == b.normal:
                result = 0
            else:
                result = cmp(a.normal, b.normal)
        else:
            result = cmp(a.texture, b.texture)

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


proc pack*(m: MaterialComponent, packed: ptr Mat4) =
    if false:
        packed[][0] = m.diffuseColor.r
        packed[][1] = m.diffuseColor.g
        packed[][2] = m.diffuseColor.b
        packed[][3] = m.entity.opacity
        packed[][4] = m.specularColor.r
        packed[][5] = m.specularColor.g
        packed[][6] = m.specularColor.b
        packed[][7] = m.shininess
        packed[][8] = if m.texture != nil: 1.0 else: 0.0
        packed[][9] = if m.normal != nil: 1.0 else: 0.0
    else:
        var o: Mat4
        o[0] = m.diffuseColor.r
        o[1] = m.diffuseColor.g
        o[2] = m.diffuseColor.b
        o[3] = m.entity.opacity
        o[4] = m.specularColor.r
        o[5] = m.specularColor.g
        o[6] = m.specularColor.b
        o[7] = m.shininess
        o[8] = if m.texture != nil: 1.0 else: 0.0
        o[9] = if m.normal != nil: 1.0 else: 0.0
        packed[] = o


func getNormalHash(d: ptr Drawable): Hash =
    result = 0
    if d.material != nil and d.material.normal != nil:
        result = hash(d.material.normal)

func getTextureHash(d: ptr Drawable): Hash =
    result = 0
    if d.material != nil and d.material.texture != nil:
        result = hash(d.material.texture)


method process*(sys: PrepareSystem, scene: Scene, input: Input,
        delta: float32) =
    if scene.root != nil:
        # Considers all the lines
        for c in iterateComponents[LineComponent](scene):
            if c.entity.visible:
                updatePoints(c)

        #var planes: array[6, Plane]
        #extractFrustumPlanes(scene.activeCamera, planes)
        #var 
        #    viewCenter: Vec3
        #    viewRadius: float32
        #    viewRadiusSqrt: float32
        
        #calculateViewCenter(scene.activeCamera, viewCenter, viewRadius)
        #viewRadiusSqrt = viewRadius * viewRadius

        # Marks invisible items
        for i in low(scene.drawables)..high(scene.drawables):
            var drawable = addr(scene.drawables[i])
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
                drawable.world = drawable.transform.world

            # Handle material
            if drawable.material == nil:
                if drawable.materialVersion != 0: 
                    drawable.materialVersion = 0
                    drawable.extra[0] = 1
                    drawable.extra[1] = 1
                    drawable.extra[2] = 1
                    drawable.extra[3] = 1
                    drawable.extra[4] = 1
                    drawable.extra[5] = 1
                    drawable.extra[6] = 1
                    drawable.extra[7] = 1
                    drawable.extra[8] = 0.0
                    drawable.extra[9] = 0.0
                    drawable.extra[10] = 0 
                    drawable.extra[11] = 0
                    drawable.extra[12] = 0 
                    drawable.extra[13] = 0
                    drawable.extra[14] = 1
                    drawable.extra[15] = 1
            else:
                if drawable.materialVersion != drawable.material.version:
                    drawable.materialVersion = drawable.material.version
                    drawable.extra[0] = drawable.material.diffuseColor.r
                    drawable.extra[1] = drawable.material.diffuseColor.g
                    drawable.extra[2] = drawable.material.diffuseColor.b
                    drawable.extra[3] = drawable.material.entity.opacity
                    drawable.extra[4] = drawable.material.specularColor.r
                    drawable.extra[5] = drawable.material.specularColor.g
                    drawable.extra[6] = drawable.material.specularColor.b
                    drawable.extra[7] = drawable.material.shininess
                    drawable.extra[8] = if drawable.material.texture != nil: 1.0 else: 0.0
                    drawable.extra[9] = if drawable.material.normal != nil: 1.0 else: 0.0
                    drawable.extra[10] = drawable.material.frameSize.x
                    drawable.extra[11] = drawable.material.frameSize.y
                    drawable.extra[12] = drawable.material.frameOffset.x
                    drawable.extra[13] = drawable.material.frameOffset.y

                if drawable.material.texture != nil and drawable.mesh.version != drawable.meshVersion and drawable.mesh of SpriteComponent:
                    drawable.meshVersion = drawable.mesh.version
                    drawable.extra[14] = drawable.material.texture.ratio.x
                    drawable.extra[15] = drawable.material.texture.ratio.y
 

                
                


