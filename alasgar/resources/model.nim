import tables

import resource
import ../core
import ../mesh
import ../texture
import ../utils
import ../components/skin
import ../components/animation

export core, texture, utils, texture, resource, skin, animation

type
    ModelNode* = ref object
        name*: string
        parent*: string
        mesh*: string
        material*: string
        position*: Vec3
        rotation*: Quat
        scale*: Vec3

    ModelSkin* = ref object
        name*: string
        model*: string

    ModelResource* = ref object of Resource
        meshes: Table[string, Mesh]
        textures: seq[Texture]
        materials: Table[string, MaterialComponent]
        joints: seq[(string, string, Mat4)]
        skins: seq[string]
        clips: Table[string, seq[string]]
        channels: Table[string, Table[string, seq[AnimationChannel]]]
        nodes*: seq[ModelNode]

proc ensure[V](c: var Table[string, V], key: string) =
    var value: V
    if not hasKey(c, key):
        c[key] = value

proc destroyModel*(r: Resource) =
    var mr = cast[ModelResource](r)
    for mesh in values(mr.meshes):
        destroy(mesh)
    for texture in mr.textures:
        destroy(texture)
    clear(mr.materials)
    clear(mr.nodes)

proc addMesh*(r: ModelResource, nodeName: string, mesh: Mesh): Mesh = 
    result = mesh
    r.meshes[nodeName] = result
proc addMesh*(r: ModelResource, nodeName: string, vertices: var seq[Vertex]): Mesh = addMesh(r, nodeName, newMesh(vertices))
proc getMeshCount*(r: ModelResource): int = len(r.meshes)
proc hasMesh*(r: ModelResource, nodeName: string): bool = 
    for m in r.meshes.keys:
        if m == nodeName:
            return true
proc getMesh*(r: ModelResource, nodeName: string): Mesh = r.meshes[nodeName]
iterator meshes*(r: ModelResource): (string, Mesh) = 
    for k, v in pairs(r.meshes):
        yield (k, v)

proc getMaterial*(r: ModelResource, nodeName: string): MaterialComponent = r.materials[nodeName]
proc hasMaterial*(r: ModelResource, nodeName: string): bool = hasKey(r.materials, nodeName)
proc addMaterial*(r: ModelResource, nodeName: string, material: MaterialComponent): MaterialComponent = 
    r.materials[nodeName] = material
    result = material

proc hasSkin*(r: ModelResource, nodeName: string): bool = nodeName in r.skins
proc addSkin*(r: ModelResource, nodeName: string) = add(r.skins, nodeName)

proc addJoint*(r: ModelResource, nodeName: string, skin: string, inverseMatrix: Mat4) = add(r.joints, (nodeName, skin, inverseMatrix))

proc hasAnimationClip*(r: ModelResource, nodeName: string): bool = hasKey(r.clips, nodeName)
proc addAnimationClip*(r: ModelResource, nodeName: string, clipName: string) = 
    ensure(r.clips, nodeName)
    add(r.clips[nodeName], clipName)

proc hasAnimationChannel*(r: ModelResource, nodeName: string): bool = hasKey(r.channels, nodeName)
proc addAnimationChannel*(r: ModelResource, nodeName: string, clipName: string, channel: AnimationChannel) = 
    if not hasKey(r.channels, nodeName):
        r.channels[nodeName] = initTable[string, seq[AnimationChannel]]()
    if not hasKey(r.channels[nodeName], clipName):
        r.channels[nodeName][clipName] = newSeq[AnimationChannel]()
    r.channels[nodeName][clipName].add(channel)
    #ensure(r.channels, nodeName)
    #let item = (clipName, channel)
    #add(r.channels[nodeName], item)


proc addMaterial*(r: ModelResource, name: string): MaterialComponent = 
    result = new(MaterialComponent)
    r.materials[name] = result

proc hasNode*(r: ModelResource, name: string): bool = anyIt(r.nodes, it.name == name)
proc getNode*(r: ModelResource, name: string): ModelNode = 
    for it in r.nodes:
        if it.name == name:
            return it

proc addNode*(r: ModelResource, name, parent: string, position: Vec3, rotation:Quat, scale: Vec3): ModelNode =
    result = new(ModelNode)
    result.name = name
    result.parent = parent
    result.position = position
    result.rotation = rotation
    result.scale = scale
    add(r.nodes, result)

proc addTexture*(r: ModelResource, texture: Texture) =
    if not anyIt(r.textures, it == texture):
        add(r.textures, texture)    

proc toEntity*(r: Resource, scene: Scene, castShadow=false, rootName=""): Entity =
    var 
        mr = cast[ModelResource](r)
        entities = newSeq[Entity]()
        nameToEntities = initTable[string, Entity]()
        skins = initTable[string, SkinComponent]()
        clips = initTable[string, AnimationClipComponent]()
        animator = newAnimatorComponent()

    for nodeName in keys(mr.clips):
        for clipName in mr.clips[nodeName]:
            clips[clipName] = newAnimationClipComponent(animator, clipName)

    for node in mr.nodes:
        let e = newEntity(scene, node.name)
        e.transform.position = node.position
        e.transform.rotation = node.rotation
        e.transform.scale = node.scale
        add(entities, e)
        nameToEntities[node.name] = e

        # Sets node clips
        if hasAnimationClip(mr, node.name):
            for clipName in mr.clips[node.name]:
                addComponent(e, clips[clipName])

        # Sets node clips
        if hasAnimationChannel(mr, node.name):
            for clipName in keys(mr.channels[node.name]):
                #setChannels(clips[clipName], mr.channels[node.name][clipName])
                for channel in mitems(mr.channels[node.name][clipName]):
                    channel.entity = e
                    addChannel(clips[clipName], channel)

        if not isEmptyOrWhitespace(node.mesh):
            if not hasMesh(mr, node.mesh):
                echo &"Error: could not find mesh[{node.mesh}]."
            else:
                let mesh = getMesh(mr, node.mesh)
                addComponent(e, newMeshComponent(mesh)) 
                echo &"Mesh [{node.mesh}] attached to entity [{e.name}]."

                # Sets nod skin
                if hasSkin(mr, node.name):
                    skins[node.name] = newSkinComponent()
                    addComponent(e, skins[node.name])

                if isEmptyOrWhitespace(node.material):
                    echo &"Mesh[{node.mesh}] has no material."
                elif not hasMaterial(mr, node.material):
                    echo &"Error: could not find material [{node.material}]."
                else:
                    let material = getMaterial(mr, node.material)
                    if castShadow:
                        material.castShadow = true
                    addComponent(e, clone(material))

    # Handles joints
    for (nodeName, skinName, inverseMatrix) in mr.joints:
        let 
            entity = nameToEntities[nodeName]
            skin = skins[skinName]
        addComponent(entity, newJointComponent(skin, inverseMatrix))

    proc findNode(name: string): Entity =
        for e in entities:
            if e.name == name:
                return e
        echo &"Error: could not find entity [{name}]."

    proc addNode(child, parent: string) =
        let c = findNode(child)
        let p = findNode(parent)
        if not isNil(p):
            addChild(p, c)
        else:
            echo &"Error: could not find parent node [{parent}] for [{child}]."

    var results = newSeq[Entity]()
    for node in mr.nodes:
        if not isEmptyOrWhitespace(node.parent):
            echo &"Adding model[{node.name}] as child of [{node.parent}]..."
            addNode(node.name, node.parent)
        else:
            add(results, findNode(node.name))

    if len(results) == 1:
        result = results[0]
    else:
        result = newEntity(scene, "Model")
        for c in results:
            addChild(result, c)
    
    if not isEmptyOrWhitespace(rootName):
        result.name = rootName

    if len(mr.clips) > 0:
        addComponent(result, animator)


