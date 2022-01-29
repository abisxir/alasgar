import tables

import resource
import ../core
import ../mesh
import ../texture
import ../utils

type
    ModelNode* = ref object
        name*: string
        parent*: string
        mesh*: string
        material*: string

    ModelMaterial* = ref object
        diffuseColor*: Color
        diffuseTexture*: Texture
        specularColor*: Color
        normalTexture*: Texture

    ModelResource* = ref object of Resource
        meshes: Table[string, Mesh]
        textures: seq[Texture]
        materials: Table[string, ModelMaterial]
        nodes*: seq[ModelNode]

proc destroyModel*(r: Resource) =
    var mr = cast[ModelResource](r)
    for mesh in values(mr.meshes):
        destroy(mesh)
    for texture in mr.textures:
        destroy(texture)
    clear(mr.materials)
    clear(mr.nodes)

proc getMeshCount*(r: ModelResource): int = len(r.meshes)
proc hasMesh*(r: ModelResource, name: string): bool = anyIt(r.nodes, it.name == name)
proc getMesh*(r: ModelResource, name: string): Mesh = r.meshes[name]
iterator meshes*(r: ModelResource): (string, Mesh) = 
    for k, v in pairs(r.meshes):
        yield (k, v)
proc addMesh*(r: ModelResource, name: string, vertices: var seq[Vertex]): Mesh = 
    echo &"Mesh [{name}] is creating..."
    result = newMesh(vertices)
    r.meshes[name] = result

proc getMaterial*(r: ModelResource, name: string): ModelMaterial = r.materials[name]
proc hasMaterial*(r: ModelResource, name: string): bool = hasKey(r.materials, name)
proc addMaterial*(r: ModelResource, name: string): ModelMaterial = 
    result = new(ModelMaterial)
    r.materials[name] = result

proc hasNode*(r: ModelResource, name: string): bool = anyIt(r.nodes, it.name == name)
proc getNode*(r: ModelResource, name: string): ModelNode = 
    for it in r.nodes:
        if it.name == name:
            return it

proc addNode*(r: ModelResource, name, parent: string, position, rotation, scale: Vec3): ModelNode =
    result = new(ModelNode)
    result.name = name
    result.parent = parent
    add(r.nodes, result)

proc addTexture*(r: ModelResource, texture: Texture) =
    if not anyIt(r.textures, it == texture):
        add(r.textures, texture)    

proc toEntity*(r: Resource, scene: Scene): Entity =
    var mr = cast[ModelResource](r)
    var entities = newSeq[Entity]()
    echo &"Converting [{len(mr.nodes)}] models to enitites."
    for node in mr.nodes:
        let e = newEntity(scene, node.name)
        add(entities, e)
        if isEmptyOrWhitespace(node.mesh) or not hasMesh(mr, node.mesh):
            echo &"Error: could not find mesh[{node.mesh}]."
        else:
            let mesh = getMesh(mr, node.mesh)
            addComponent(e, newMeshComponent(mesh)) 
            echo &"Mesh [{node.mesh}] attached to entity [{e.name}]."

            if isEmptyOrWhitespace(node.material):
                echo &"Mesh[{node.mesh}] has no material."
            elif not hasMaterial(mr, node.material):
                echo &"Error: could not find material [{node.material}]."
            else:
                let material = getMaterial(mr, node.material)
                addComponent(e, newMaterialComponent(
                    baseColor=material.diffuseColor,
                    emmisiveColor=material.specularColor,
                    albedoMap=material.diffuseTexture,
                    normalMap=material.normalTexture
                ))

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

    for e in results:
        let mesh = getComponent[MeshComponent](e)
        if isNil(mesh):
            echo &"[{e}] Has no mesh :/"

    if len(results) == 1:
        result = results[0]
    else:
        result = newEntity(scene, "Model")
        for c in results:
            addChild(result, c)


