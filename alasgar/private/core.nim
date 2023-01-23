import strformat
import sequtils
import sugar
import strutils
import tables
import typetraits

import config
import utils
import input
import mesh
import texture
import shader

export utils, input, mesh, texture, config

type
    Component* = ref object of RootObj
        version*: int16
        entity: Entity

    ContainerBase = ref object of RootObj
        entities: seq[Entity]
        components: seq[Component]

    Container[T] = ref object of ContainerBase
        head: T

    Scene* = ref object
        entities: seq[Entity]
        containers: seq[ContainerBase]
        tags: Table[string, seq[Entity]]
        root*: Entity
        drawables*: seq[Drawable]

    Entity* = ref object
        id: int
        name*: string
        tag*: string
        layer*: int32
        opacity*: float32
        scene: Scene
        transform: TransformComponent
        parent: Entity
        children: seq[Entity]
        components: seq[(Component, ContainerBase)]
        visible: bool
        attached: bool
        wasted: bool

    TransformComponent* = ref object of Component
        local: Mat4
        world: Mat4
        position: Vec3
        scale: Vec3
        rotation: Quat
        valid: bool
        localIsUpdated: bool

    MaterialMapEnum = enum
        albedoMaterialMap =    0b000001
        normalMaterialMap =    0b000010
        metallicMaterialMap =  0b000100
        roughnessMaterialMap = 0b001000
        aoMaterialMap =        0b010000
        emissiveMaterialMap =  0b100000

    MaterialComponent* = ref object of Component
        diffuseColor: Color
        specularColor: Color
        emissiveColor: Color
        metallic: float32
        roughness: float32
        reflectance: float32
        ao: float32
        
        albedoMap: Texture
        normalMap: Texture
        metallicMap: Texture
        roughnessMap: Texture
        aoMap: Texture
        emissiveMap: Texture
        availableMaps: uint32
        uvChannels: uint32

        vframes: int32
        hframes: int32
        frame: int32
        frameSize: Vec2
        frameOffset: Vec2
        castShadow*: bool

    MeshComponent* = ref object of Component
        instance*: Mesh

    SkinComponent* = ref object of Component
        joints*: seq[JointComponent]
        texture*: Texture
        offset*: int
        count*: int

    JointComponent* = ref object of Component
        inverseMatrix*: Mat4
        model*: Mat4

    SpriteComponent* = ref object of MeshComponent
    ShaderComponent* = ref object of Component
        instance: Shader

    Drawable* = object
        modelPack*: Mat4
        materialPack*: array[4, uint32]
        spritePack*: Vec4
        skinPack*: Vec4
        transform*: TransformComponent
        mesh*: MeshComponent
        material*: MaterialComponent
        shader*: ShaderComponent
        skin*: SkinComponent
        count*: int32
        visible*: bool
        meshVersion*: int16
        materialVersion*: int16
        transformVersion*: int16


# Forward declarations
proc ensureContainer[T](scene: Scene): Container[T]
proc removeChild*(n: Entity, child: Entity)
proc newTransform*(): TransformComponent
proc `model`*(t: TransformComponent): var Mat4
proc `dirty`*(t: TransformComponent): bool
proc findEntityByTag*(scene: Scene, tag: string): seq[Entity]
func getComponent*[T: Component](e: Entity): T
proc `inc`(c: Component)

# Shader implementation
proc `instance`*(shader: ShaderComponent): Shader = shader.instance
proc newShaderComponent*(instance: Shader): ShaderComponent =
    new(result)
    result.instance = instance

# Entity implmentation
proc `$`*(e: Entity): string = &"{e.id}:{e.name}"
proc findDrawable(scene: Scene, mesh: MeshComponent): ptr Drawable =
    result = nil
    for i, item in mpairs(scene.drawables):
        if item.mesh == mesh:
            result = addr(scene.drawables[i])
            break

proc updateDrawable(e: Entity, c: Component) =
    # Handles drawables
    if c of MeshComponent:
        let mesh = cast[MeshComponent](c)
        let material = getComponent[MaterialComponent](e)
        let skin = getComponent[SkinComponent](e)
        let shader = getComponent[ShaderComponent](e)
        add(e.scene.drawables,
            Drawable(
                transform: e.transform,
                mesh: mesh,
                material: material,
                skin: skin,
                shader: shader,
                transformVersion: -1.int16,
                materialVersion: -1.int16
            ))
    elif c of MaterialComponent:
        let material = cast[MaterialComponent](c)
        let mesh = getComponent[MeshComponent](e)
        if mesh != nil:
            var drawable = findDrawable(e.scene, mesh)
            if drawable != nil:
                drawable.material = material
    elif c of SkinComponent:
        let skin = cast[SkinComponent](c)
        let mesh = getComponent[MeshComponent](e)
        if mesh != nil:
            var drawable = findDrawable(e.scene, mesh)
            if drawable != nil:
                drawable.skin = skin
    elif c of ShaderComponent:
        let shader = cast[ShaderComponent](c)
        let mesh = getComponent[MeshComponent](e)
        if mesh != nil:
            var drawable = findDrawable(e.scene, mesh)
            if drawable != nil:
                drawable.shader = shader

proc removeDrawable(scene: Scene, mesh: MeshComponent) =
    var found = false
    var i = 0
    while i < len(scene.drawables):
        if scene.drawables[i].mesh == mesh:
            found = true
            break
        inc(i)

    if found:
        del(scene.drawables, i)

iterator iterateComponents*[T: Component](scene: Scene): T =
    var 
        container: Container[T] = ensureContainer[T](scene)
    for c in container.components:
        if c.entity.attached:
            yield cast[T](c)

proc addComponent*[T](e: Entity, c: T) =
    var container: Container[T] = ensureContainer[T](e.scene)
    c.entity = e
    add(container.components, c)
    add(e.components, (c, container))

    # Updates drawable
    updateDrawable(e, cast[Component](c))

proc addComponent*[T](scene: Scene, c: T) = addComponent[T](scene.root, c)

proc removeComponent*[T](e: Entity) =
    var toRemoveList = newSeq[(Component, ContainerBase)]()
    for i in low(e.components)..high(e.components):
        var pack = e.components[i]
        var component = pack[0]
        var container = pack[1]
        if component of T:
            delete(container.components, component)
            component.entity = nil
            delete(container.entities, e)
            toRemoveList.add(pack)

            # Removes from drawables
            if component of MeshComponent:
                removeDrawable(e.scene, cast[MeshComponent](component))

    for pack in toRemoveList:
        delete(e.components, pack)


proc removeComponent*[T](e: Entity, c: T) =
    while len(e.components) > 0:
        var component = e.components[0][0]
        var container = e.components[0][1]
        if component == c:
            delete(e.components, 0)
            delete(container.components, component)
            component.entity = nil
            break

proc removeComponent*[T](scene: Scene, c: T) = removeComponent[T](scene.root, c)

proc removeComponents*(e: Entity) =
    while len(e.components) > 0:
        var component = e.components[0][0]
        var container = e.components[0][1]
        delete(e.components, 0)
        delete(container.components, component)
        component.entity = nil

proc destroy*(e: Entity) = e.wasted = true

proc cleanup(e: Entity) =
    if e.parent != nil:
        removeChild(e.parent, e)
    if e.scene != nil:
        delete(e.scene.entities, e)
        removeComponents(e)
        e.scene = nil
        while len(e.children) > 0:
            cleanup(e.children[0])

proc rebase*(e: Entity, parent: Mat4, parentIsDirty: bool): var Mat4 =
    if parentIsDirty or e.transform.dirty:
        e.transform.world = parent * e.transform.model
        e.transform.valid = true
        inc(e.transform)

    result = e.transform.world



proc setAttach(e: Entity, flag: bool) =
    if not isEmptyOrWhitespace(e.tag):
        if flag:
            if not hasKey(e.scene.tags, e.tag):
                e.scene.tags[e.tag] = @[e]
            else:
                add(e.scene.tags[e.tag], e)
        else:
            var i = find(e.scene.tags[e.tag], e)
            if i >= 0:
                del(e.scene.tags[e.tag], i)
    e.attached = flag
    for c in e.children:
        setAttach(c, flag)

proc addChild*(n: Entity, child: Entity) =
    #echo &"Adding [{child}] to [{n}]"
    if child.parent == nil:
        add(n.children, child)
        child.parent = n
        child.scene = n.scene
        setAttach(child, n.attached)

proc removeChild*(n: Entity, child: Entity) =
    let count = n.children.len()
    n.children = n.children.filter(c => c != child)
    if count > n.children.len:
        setAttach(child, false)
        child.parent = nil
        child.scene = nil

proc removeChildren*(n: Entity) =
    while len(n.children) > 0:
        removeChild(n, n.children[0])

proc getChild*(n: Entity, name: string): Entity =
    for child in n.children:
        if child.name == name:
            result = child
            break


iterator `children`*(n: Entity): Entity =
    for child in n.children:
        yield child

proc getComponent*[T: Component](e: Entity, r: var T) =
    r = nil
    for i in low(e.components)..high(e.components):
        var c = e.components[i][0]
        if c of T:
            r = cast[T](c)

proc `visible=`*(e: Entity, value: bool) =
    e.visible = value

proc `visible`*(e: Entity): bool =
    if e.parent != nil:
        e.parent.visible and e.visible
    else:
        e.visible and not e.wasted

func getComponent*[T: Component](e: Entity): T = getComponent(e, result)
func `[]`*[T](e: Entity, row: typedesc[T]): T = getComponent[T](e)
func getChildrenCount*(n: Entity): int = n.children.len
func getChild*(n: Entity, i: int): Entity = n.children[i]
func hasChild*(n: Entity, name: string): bool = getChild(n, name) != nil
func `$`*(n: Entity): string = n.name
proc `head`(n: Entity): Entity = result = if isNil(n.parent): n else: n.parent.head
template `transform`*(e: Entity): TransformComponent = e.transform
template `root`*(n: Entity): Entity = head n
template `parent`*(n: Entity): Entity = n.parent
template `scene`*(n: Entity): Scene = n.scene
template `attached`*(n: Entity): bool = n.attached
iterator `components`*(n: Entity): Component =
    for c in n.components:
        yield c[0]
func hash*(e: Entity): Hash = hash(cast[pointer](e))
func `id`*(e: Entity): int = e.id

proc findEntity(n: Entity, names: openArray[string]): Entity =
    if names.len > 1:
        var child = getChild(n, names[0])
        if child != nil:
            result = findEntity(child, names[1..names.high])
    elif names.len == 1:
        result = getChild(n, names[0])

proc findEntity*(n: Entity, path: string): Entity =
    var names = path.split '/'
    if names.len > 0:
        if startsWith(path, "/"):
            result = findEntity(n.head, names[1..names.high])
        elif startsWith(path, "../") and n.parent != nil:
            result = findEntity(n.parent, names[1..names.high])
        elif startsWith(path, "./"):
            result = findEntity(n, names[1..names.high])
        else:
            result = n.findEntity names

proc findEntityByTag*(n: Entity, tag: string): seq[Entity] = findEntityByTag(
        n.scene, tag)

# Component implementation
proc `inc`(c: Component) = c.version = if c.version == high(int16): 0.int16 else: c.version + 1.int16
func `transform`*(c: Component): TransformComponent = c.entity[].transform
func `entity`*(c: Component): Entity = c.entity
func `scene`*(c: Component): Scene = c.entity.scene
func getComponent*[T: Component](c: Component): T = getComponent(c.entity, result)
func `[]`*[T](c: Component, row: typedesc[T]): T = getComponent[T](c.entity)
func hash*(c: Component): Hash = hash(unsafeAddr(c))
method cleanup*(c: Component) {.base.} = discard


# Scene implementation
proc ensureContainer[T](scene: Scene): Container[T] =
    for c in scene.containers:
        if c of Container[T]:
            result = cast[Container[T]](c)
            break
    if result == nil:
        result = new(Container[T])
        add(scene.containers, result)


proc newEntity*(scene: Scene, name: string, tag: string = "",
        parent: Entity = nil): Entity =
    var lastEntityId {.global.} = 0
    inc(lastEntityId)
    result = Entity.new
    result.id = lastEntityId
    result.name = name
    result.tag = tag
    result.scene = scene
    result.visible = true
    result.attached = false
    result.wasted = false
    result.opacity = 1
    add(scene.entities, result)
    echo &"Entity [{result.id}] with name [{result.name}] created!"
    result.transform = newTransform()
    addComponent(result, result.transform)
    if parent != nil:
        addChild(parent, result)

proc newScene*(): Scene =
    result = new(Scene)
    result.root = newEntity(result, name = "Root")
    result.root.scene = result
    result.root.attached = true

proc addChild*(scene: Scene, entity: Entity) =
    addChild(scene.root, entity)

proc forEachComponent*[T: Component](scene: Scene, fn: proc(component: T)) =
    var container: Container[T] = ensureContainer[T](scene)
    for i in low(container.components)..high(container.components):
        var c: T = cast[T](container.components[i])
        if c.entity.attached:
            fn(c)

proc forEachComponent*[T: Component](scene: Scene, input: Input, delta: float32,
        fn: proc(component: T, input: Input, delta: float32)) =
    var container: Container[T] = ensureContainer[T](scene)
    for i in low(container.components)..high(container.components):
        var c: T = cast[T](container.components[i])
        if c.entity.attached:
            fn(c, input, delta)

func first*[T: Component](scene: Scene): T =
    var container: Container[T] = ensureContainer[T](scene)
    if len(container.components) > 0:
        result = cast[T](container.components[0])

func getComponentsCount*[T: Component](scene: Scene): int =
    var container: Container[T] = ensureContainer[T](scene)
    result = len(container.components)

proc findEntityByTag*(scene: Scene, tag: string): seq[Entity] =
    if hasKey(scene.tags, tag):
        result = scene.tags[tag]

func hasComponent*[T: Component](scene: Scene): bool = getComponentsCount[T](scene) > 0
func size*(scene: Scene): int = len(scene.entities)

proc destroy*(scene: Scene) =
    if not isNil(scene):
        for e in mitems(scene.drawables):
            e.transform = nil
            e.mesh = nil
            e.material = nil
            e.shader = nil
        clear(scene.drawables)
    
        for e in mitems(scene.entities):
            e.scene = nil
            e.transform = nil
            e.parent = nil
            clear(e.children)
            for c in e.components:
                cleanup(c[0])
                c[0].entity = nil
            clear(e.components)

        clear(scene.containers)
        clear(scene.tags)
        scene.root = nil

proc cleanup*(scene: Scene) =
    var wasteds = filterIt(scene.entities, it.wasted)
    for e in wasteds:
        cleanup(e)

# Transform implementation
proc newTransform*(): TransformComponent =
    new(result)
    result.scale = VEC3_ONE
    result.rotation = quat(0, 0, 0, 1)
    result.world = mat4()

proc markDirty(t: TransformComponent) =
    t.localIsUpdated = false
    t.valid = false

proc mat4(t: TransformComponent): Mat4 =
    var x = t.rotation * VEC3_RIGHT # Vec3 * Quat (right vector)
    var y = t.rotation * VEC3_UP # Vec3 * Quat (up vector)
    var z = t.rotation * VEC3_BACK # Vec3 * Quat (forward vector)

    # Next, scale the basis vectors
    x = x * t.scale.x # Vector * float
    y = y * t.scale.y # Vector * float
    z = z * t.scale.z # Vector * float

    # Create matrix
    result = mat4(
        x.x, x.y, x.z, 0, # X basis (& Scale)
        y.x, y.y, y.z, 0, # Y basis (& scale)
        z.x, z.y, z.z, 0, # Z basis (& scale)
        t.position.x, t.position.y, t.position.z, 1 # Position
    )

proc `model`*(t: TransformComponent): var Mat4 =
    if not t.localIsUpdated:
        t.local = mat4(t)
        t.localIsUpdated = true
        inc(t)
    result = t.local

proc `model=`*(t: TransformComponent, model: Mat4) =
    t.position = pos(model)
    t.rotation = quat(model)
    t.scale = scale(model)
    markDirty(t)

proc `position=`*(t: TransformComponent, position: Vec3) =
    t.position = position
    markDirty(t)

proc `positionX=`*(t: TransformComponent, x: float32) =
    t.position.x = x
    markDirty(t)

proc `positionY=`*(t: TransformComponent, y: float32) =
    t.position.y = y
    markDirty(t)

proc `positionZ=`*(t: TransformComponent, z: float32) =
    t.position.z = z
    markDirty(t)

proc `scale=`*(t: TransformComponent, scale: Vec3) =
    t.scale = scale
    markDirty(t)

proc `scaleX=`*(t: TransformComponent, x: float32) =
    t.scale.x = x
    markDirty(t)

proc `scaleY=`*(t: TransformComponent, y: float32) =
    t.scale.y = y
    markDirty(t)

proc `scaleZ=`*(t: TransformComponent, z: float32) =
    t.scale.z = z
    markDirty(t)

proc `rotation=`*(t: TransformComponent, r: Quat) =
    t.rotation = r
    markDirty(t)

proc `euler=`*(t: TransformComponent, v: Vec3) =
    t.rotation = fromEuler(v)
    markDirty(t)

template `parent`*(t: TransformComponent): TransformComponent =
    if t.entity.parent != nil:
        t.entity.parent.transform
    else:
        nil

proc isHierarchyDirty*(t: TransformComponent): bool =
    if t.dirty:
        return true
    var it = t.parent
    while it != nil:
        if it.dirty:
            return true
        else:
            it = it.parent
    return false

proc getActualWorld*(t: TransformComponent): Mat4 =
    if isHierarchyDirty(t):
        if t.parent != nil:
            result = getActualWorld(t.parent.transform) * t.model
        else:
            result = t.model
    else:
        result = t.world

proc `globalPosition`*(t: TransformComponent): Vec3 =
    var world = getActualWorld(t)
    vec3(world[12], world[13], world[14])

proc `globalScale`*(t: TransformComponent): Vec3 =
    var world = getActualWorld(t)
    result.x = length(vec3(world[0], world[4], world[8]))
    result.y = length(vec3(world[1], world[5], world[9]))
    result.z = length(vec3(world[2], world[6], world[10]))

proc `globalRotation`*(t: TransformComponent): Quat =
    var world = getActualWorld(t)
    quat(world)

proc `globalPosition=`*(t: TransformComponent, position: Vec3) =
    var wmNow = getActualWorld(t)
    var dir = position - wmNow.pos
    t.position = t.position + dir
    markDirty(t)

proc `globalScale=`*(t: TransformComponent, scale: Vec3) =
    var world = getActualWorld(t)
    var ratio = vec3(world[0] / scale.x, world[5] / scale.y, world[10] / scale.z)
    t.scale = t.scale * ratio
    markDirty(t)

proc `globalRotation=`*(t: TransformComponent, r: Quat) =
    if t.parent == nil:
        t.rotation = r
    else:
        var pr = t.parent.globalRotation
        t.rotation = inverse(pr) * r
    markDirty(t)

proc lookAt*(t: TransformComponent, target: Vec3, up: Vec3 = VEC3_UP) =
    t.globalRotation = quat(inverse(lookAt(target, t.globalPosition, up)))
    #var direction = target - t.transform.globalPosition
    #t.globalRotation = lookAt(direction)
    markDirty(t)


proc lookAt*(t: TransformComponent, target: TransformComponent,
        up: Vec3 = VEC3_UP) =
    lookAt(t, target.globalPosition, up)

proc `world=`*(t: TransformComponent, world: Mat4) =
    t.world = world
    t.valid = true

proc `rotation`*(t: TransformComponent): Quat = t.rotation
proc `position`*(t: TransformComponent): Vec3 = t.position
proc `positionX`*(t: TransformComponent): float32 = t.position.x
proc `positionY`*(t: TransformComponent): float32 = t.position.y
proc `positionZ`*(t: TransformComponent): float32 = t.position.z
#proc `eulerX`*(t: Transform): float32 = t.euler.x
#proc `eulerY`*(t: Transform): float32 = t.euler.y
#proc `eulerZ`*(t: Transform): float32 = t.euler.z
proc `scale`*(t: TransformComponent): Vec3 = t.scale
proc `world`*(t: TransformComponent): var Mat4 = t.world
proc `dirty`*(t: TransformComponent): bool = not t.valid
proc `$`*(t: TransformComponent): string = &"pos:{t.position} rotation:{t.rotation} scale:{t.scale}"
func hash*(t: TransformComponent): Hash = hash(cast[pointer](t))

# Mesh implementation
func newMeshComponent*(instance: Mesh): MeshComponent =
    new(result)
    result.instance = instance

func hash*(m: MeshComponent): Hash = hash(cast[pointer](m))

# Material implementaion
func updateAvailableMaps(m: MaterialComponent) =
    m.availableMaps = 0
    m.uvChannels = 0
    if not isNil(m.albedoMap):
        m.availableMaps = m.availableMaps or albedoMaterialMap.uint32
        if m.albedoMap.uvChannel == 1:
            m.uvChannels = m.uvChannels or albedoMaterialMap.uint32
    if not isNil(m.metallicMap):
        m.availableMaps = m.availableMaps or metallicMaterialMap.uint32
        if m.metallicMap.uvChannel == 1:
            m.uvChannels = m.uvChannels or metallicMaterialMap.uint32
    if not isNil(m.roughnessMap):
        m.availableMaps = m.availableMaps or roughnessMaterialMap.uint32
        if m.roughnessMap.uvChannel == 1:
            m.uvChannels = m.uvChannels or roughnessMaterialMap.uint32
    if not isNil(m.normalMap):
        m.availableMaps = m.availableMaps or normalMaterialMap.uint32
        if m.normalMap.uvChannel == 1:
            m.uvChannels = m.uvChannels or normalMaterialMap.uint32
    if not isNil(m.aoMap):
        m.availableMaps = m.availableMaps or aoMaterialMap.uint32
        if m.aoMap.uvChannel == 1:
            m.uvChannels = m.uvChannels or aoMaterialMap.uint32
    if not isNil(m.emissiveMap):
        m.availableMaps = m.availableMaps or emissiveMaterialMap.uint32
        if m.emissiveMap.uvChannel == 1:
            m.uvChannels = m.uvChannels or emissiveMaterialMap.uint32

func newPBRMaterialComponent*(diffuseColor: Color=COLOR_WHITE, 
        specularColor: Color=COLOR_WHITE, 
        emissiveColor: Color=COLOR_BLACK,
        albedoMap, normalMap, metallicMap, roughnessMap, aoMap, emissiveMap: Texture = nil, 
        metallic: float32 = 1.0,
        roughness: float32 = 1.0,
        reflectance: float32 = 1.0,
        ao: float32 = 1,
        frame: int32=0,
        vframes: int32=1,
        hframes: int32=1,
        castShadow: bool=false): MaterialComponent =
    new(result)
    result.diffuseColor = diffuseColor
    result.specularColor = specularColor
    result.emissiveColor = emissiveColor
    result.metallic = metallic
    result.roughness = roughness
    result.reflectance = reflectance
    result.ao = ao
    result.albedoMap = albedoMap
    result.normalMap = normalMap
    result.metallicMap = metallicMap
    result.roughnessMap = roughnessMap
    result.aoMap = aoMap
    result.emissiveMap = emissiveMap
    result.frame = max(0, frame)
    result.vframes = max(1, vframes)
    result.hframes = max(1, hframes)
    result.frameSize = vec2(1, 1)
    result.frameOffset = vec2(0, 0)
    result.castShadow = castShadow
    updateAvailableMaps(result)


proc newMaterialComponent*(diffuseColor: Color=COLOR_WHITE, 
        specularColor: Color=COLOR_WHITE, 
        emissiveColor: Color=COLOR_BLACK,
        albedoMap: Texture=nil, 
        normalMap: Texture=nil, 
        shininess: float32 = 150.0 / 255.0,
        frame: int32=0,
        vframes: int32=1,
        hframes: int32=1,
        castShadow: bool=false): MaterialComponent =
    result = newPBRMaterialComponent(
        diffuseColor=diffuseColor,
        specularColor=specularColor,
        albedoMap=albedoMap,
        normalMap=normalMap,
        frame=frame,
        vframes=vframes,
        hframes=hframes,
        castShadow=castShadow,
        metallic=0.0,
        roughness=shininess,
    )
    result.roughness = clamp(result.roughness, 0.0, 255.0)

func `diffuseColor=`*(m: MaterialComponent, value: Color) =
    m.diffuseColor = value
    inc(m)

func `specularColor=`*(m: MaterialComponent, value: Color) =
    m.specularColor = value
    inc(m)

func `emissiveColor=`*(m: MaterialComponent, emissiveColor: Color) =
    m.emissiveColor = emissiveColor
    inc(m)

func `roughness=`*(m: MaterialComponent, value: float32) =
    m.roughness = value
    inc(m)

func `metallic=`*(m: MaterialComponent, value: float32) =
    m.metallic = value
    inc(m)

func `reflectance=`*(m: MaterialComponent, value: float32) =
    m.reflectance = value
    inc(m)

func `ao=`*(m: MaterialComponent, value: float32) =
    m.ao = value
    inc(m)

func `albedoMap=`*(m: MaterialComponent, value: Texture) =
    m.albedoMap = value
    inc(m)
    updateAvailableMaps(m)

func `normalMap=`*(m: MaterialComponent, value: Texture) =
    m.normalMap = value
    inc(m)
    updateAvailableMaps(m)

func `metallicMap=`*(m: MaterialComponent, value: Texture) =
    m.metallicMap = value
    inc(m)
    updateAvailableMaps(m)

func `roughnessMap=`*(m: MaterialComponent, value: Texture) =
    m.roughnessMap = value
    inc(m)
    updateAvailableMaps(m)

func `aoMap=`*(m: MaterialComponent, value: Texture) =
    m.aoMap = value
    inc(m)
    updateAvailableMaps(m)

func `emissiveMap=`*(m: MaterialComponent, value: Texture) =
    m.emissiveMap = value
    inc(m)
    updateAvailableMaps(m)

template `albedoMap`*(m: MaterialComponent): Texture = m.albedoMap
template `normalMap`*(m: MaterialComponent): Texture = m.normalMap
template `metallicMap`*(m: MaterialComponent): Texture = m.metallicMap
template `roughnessMap`*(m: MaterialComponent): Texture = m.roughnessMap
template `aoMap`*(m: MaterialComponent): Texture = m.aoMap
template `emissiveMap`*(m: MaterialComponent): Texture = m.emissiveMap
template `diffuseColor`*(m: MaterialComponent): Color = m.diffuseColor
template `specularColor`*(m: MaterialComponent): Color = m.specularColor
template `emissiveColor`*(m: MaterialComponent): Color = m.emissiveColor
template `roughness`*(m: MaterialComponent): float32 = m.roughness
template `shininess`*(m: MaterialComponent): float32 = m.roughness
template `metallic`*(m: MaterialComponent): float32 = m.metallic
template `reflectance`*(m: MaterialComponent): float32 = m.reflectance
template `ao`*(m: MaterialComponent): float32 = m.ao
template `frame`*(material: MaterialComponent): int = material.frame
template `vframes`*(material: MaterialComponent): int = material.vframes
template `hframes`*(material: MaterialComponent): int = material.hframes
template `availableMaps`*(material: MaterialComponent): uint32 = material.availableMaps
template `uvChannels`*(material: MaterialComponent): uint32 = material.uvChannels

func update(material: MaterialComponent) =
    if material.hframes > 0 and material.vframes > 0:
        let fxy = vec2(float32(material.frame mod material.hframes), float32(material.vframes - (material.frame div material.hframes) - 1))
        material.frameSize = vec2(1.float32 / material.hframes.float32, 1.float32 / material.vframes.float32)
        material.frameOffset = vec2(fxy.x * material.frameSize.x, fxy.y * material.frameSize.y)    
        inc(material)

template `frame=`*(material: MaterialComponent, value: int) =
    material.frame = value
    if material.frame < 0:
        material.frame = 0
    let framesCount = max(0, (material.hframes * material.vframes) - 1)
    if material.frame > framesCount:
        material.frame = framesCount
    update(material)

template `vframes=`*(material: MaterialComponent, value: int) =
    if value > 0:
        material.vframes = value
        update(material) 

template `hframes=`*(material: MaterialComponent, value: int) =
    if value > 0:
        material.hframes = value
        update(material) 

template `frameSize`*(material: MaterialComponent): Vec2 = material.frameSize
template `frameOffset`*(material: MaterialComponent): Vec2 = material.frameOffset

proc `$`*(m: MaterialComponent): string = 
    if not isNil(m):
        &"base:{m.diffuseColor} emissive:{m.emissiveColor}"
    else:
        &"nil"

proc clone*(m: MaterialComponent): MaterialComponent =
    new(result)
    result.diffuseColor = m.diffuseColor
    result.specularColor = m.specularColor
    result.emissiveColor = m.emissiveColor
    result.metallic = m.metallic
    result.roughness = m.roughness
    result.reflectance = m.reflectance
    result.ao = m.ao
    result.albedoMap = m.albedoMap
    result.normalMap = m.normalMap
    result.metallicMap = m.metallicMap
    result.roughnessMap = m.roughnessMap
    result.aoMap = m.aoMap
    result.emissiveMap = m.emissiveMap
    result.frame = m.frame
    result.vframes = m.vframes
    result.hframes = m.hframes
    result.frameSize = m.frameSize
    result.frameOffset = m.frameOffset
    result.castShadow = m.castShadow
    updateAvailableMaps(result)    
