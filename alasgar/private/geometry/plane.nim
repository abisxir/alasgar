import tables

import ../core
import ../utils

var meshes = initTable[(float32, float32, int, int), Mesh]()

#[

    {{ 1.0f, -1.0f, 0.0f}, {0.0f, 0.0f, 1.0f}},
    {{ 1.0f,  1.0f, 0.0f}, {0.0f, 0.0f, 1.0f}},
    {{-1.0f, -1.0f, 0.0f}, {0.0f, 0.0f, 1.0f}},
    {{-1.0f,  1.0f, 0.0f}, {0.0f, 0.0f, 1.0f}}
};
constexpr Trade::MeshAttributeData AttributesSolid[]{
    Trade::MeshAttributeData{Trade::MeshAttribute::Position,
        Containers::stridedArrayView(VerticesSolid, &VerticesSolid[0].position,
            Containers::arraySize(VerticesSolid), sizeof(VertexSolid))},
    Trade::MeshAttributeData{Trade::MeshAttribute::Normal,
        Containers::stridedArrayView(VerticesSolid, &VerticesSolid[0].normal,
            Containers::arraySize(VerticesSolid), sizeof(VertexSolid))}
};

}

Trade::MeshData planeSolid() {
    return Trade::MeshData{MeshPrimitive::TriangleStrip,
        {}, VerticesSolid,
        Trade::meshAttributeDataNonOwningArray(AttributesSolid)};
}

Trade::MeshData planeSolid(const PlaneFlags flags) {
    /* Return the compile-time data if nothing extra is requested */
    if(!flags) return planeSolid();

    /* Calculate attribute count and vertex size */
    std::size_t stride = sizeof(Vector3) + sizeof(Vector3);
    std::size_t attributeCount = 2;
    if(flags & PlaneFlag::Tangents) {
        stride += sizeof(Vector4);
        ++attributeCount;
    }
    if(flags & PlaneFlag::TextureCoordinates) {
        stride += sizeof(Vector2);
        ++attributeCount;
    }

    /* Set up the layout */
    Containers::Array<char> vertexData{Containers::NoInit, 4*stride};
    Containers::Array<Trade::MeshAttributeData> attributeData{attributeCount};
    std::size_t attributeIndex = 0;
    std::size_t attributeOffset = 0;

    Containers::StridedArrayView1D<Vector3> positions{vertexData,
        reinterpret_cast<Vector3*>(vertexData.data() + attributeOffset),
        4, std::ptrdiff_t(stride)};
    attributeData[attributeIndex++] = Trade::MeshAttributeData{
        Trade::MeshAttribute::Position, positions};
    attributeOffset += sizeof(Vector3);

    Containers::StridedArrayView1D<Vector3> normals{vertexData,
        reinterpret_cast<Vector3*>(vertexData.data() + sizeof(Vector3)),
        4, std::ptrdiff_t(stride)};
    attributeData[attributeIndex++] = Trade::MeshAttributeData{
        Trade::MeshAttribute::Normal, normals};
    attributeOffset += sizeof(Vector3);

    Containers::StridedArrayView1D<Vector4> tangents;
    if(flags & PlaneFlag::Tangents) {
        tangents = Containers::StridedArrayView1D<Vector4>{vertexData,
            reinterpret_cast<Vector4*>(vertexData.data() + attributeOffset),
            4, std::ptrdiff_t(stride)};
        attributeData[attributeIndex++] = Trade::MeshAttributeData{
            Trade::MeshAttribute::Tangent, tangents};
        attributeOffset += sizeof(Vector4);
    }

    Containers::StridedArrayView1D<Vector2> textureCoordinates;
    if(flags & PlaneFlag::TextureCoordinates) {
        textureCoordinates = Containers::StridedArrayView1D<Vector2>{vertexData,
            reinterpret_cast<Vector2*>(vertexData.data() + attributeOffset),
            4, std::ptrdiff_t(stride)};
        attributeData[attributeIndex++] = Trade::MeshAttributeData{
            Trade::MeshAttribute::TextureCoordinates, textureCoordinates};
        attributeOffset += sizeof(Vector2);
    }

    CORRADE_INTERNAL_ASSERT(attributeIndex == attributeCount);
    CORRADE_INTERNAL_ASSERT(attributeOffset == stride);

    /* Fill the data */
    for(std::size_t i = 0; i != 4; ++i) {
        positions[i] = VerticesSolid[i].position;
        normals[i] = VerticesSolid[i].normal;
        if(flags & PlaneFlag::Tangents)
            tangents[i] = {1.0f, 0.0f, 0.0f, 1.0f};
    }
    if(flags & PlaneFlag::TextureCoordinates) {
        textureCoordinates[0] = {1.0f, 0.0f};
        textureCoordinates[1] = {1.0f, 1.0f};
        textureCoordinates[2] = {0.0f, 0.0f};
        textureCoordinates[3] = {0.0f, 1.0f};

    {{ 1.0f, -1.0f, 0.0f}, {0.0f, 0.0f, 1.0f}},
    {{ 1.0f,  1.0f, 0.0f}, {0.0f, 0.0f, 1.0f}},
    {{-1.0f, -1.0f, 0.0f}, {0.0f, 0.0f, 1.0f}},
    {{-1.0f,  1.0f, 0.0f}, {0.0f, 0.0f, 1.0f}}
]#

proc createPlaneMesh(width, height: float32) =
    var vertices = [
        Vertex(position: vec3(width, -height, 0), normal: vec3(0, 0, 1), uv: vec2(1, 0)), 
        Vertex(position: vec3(width, height, 0), normal: vec3(0, 0, 1), uv: vec2(1, 1)),
        Vertex(position: vec3(-width, -height, 0), normal: vec3(0, 0, 1), uv: vec2(0, 0)),
        Vertex(position: vec3(-width, height, 0), normal: vec3(0, 0, 1), uv: vec2(0, 1)),
    ]

    meshes[(width, height, 1, 1)] = newMeshStrip(vertices)

proc createPlaneMeshx(width, height: float32) =
    let normal = -VEC3_FORWARD
    var vertices = [
        Vertex(position: vec3(0, 0, 0), normal: normal, uv: vec2(0, 0)), 
        Vertex(position: vec3(width, 0, 0), normal: normal, uv: vec2(1, 0)),
        Vertex(position: vec3(0, height, 0), normal: normal, uv: vec2(0, 1)),
        Vertex(position: vec3(width, height, 0), normal: normal, uv: vec2(1, 1)),
    ]

    var indices = [
        # lower left triangle
        0.uint32, 2, 1,
        # upper right triangle
        2, 3, 1
    ]        

    meshes[(width, height, 1, 1)] = newMesh(vertices, indices)    

#[
proc createPlaneMesh(width, height: float32, vSectors, hSectors: int) = 
    let xoffset = -width 
    let yoffset = -height
    let lx = (width * 2) / vSectors.float32
    let ly = (height * 2) / hSectors.float32
    let normal = vec3(0, 1, 0)
    var vertexes = newSeq[Vertex]()

    for j in 0..hSectors - 1:
        let ty = yoffset + ly * j.float32
        for i in 0..vSectors - 1:
            let tx = xoffset + lx * i.float32
            vertexes.add(Vertex(position: vec3(tx + lx, 0, ty), normal: normal, uv: vec2(1, 0)))
            vertexes.add(Vertex(position: vec3(tx, 0, ty + ly), normal: normal, uv: vec2(0, 1)))
            vertexes.add(Vertex(position: vec3(tx, 0, ty), normal: normal, uv: vec2(0, 0)))

            vertexes.add(Vertex(position: vec3(tx + lx, 0, ty), normal: normal, uv: vec2(1, 0)))
            vertexes.add(Vertex(position: vec3(tx, 0, ty + ly), normal: normal, uv: vec2(0, 1)))
            vertexes.add(Vertex(position: vec3(tx + lx, 0, ty + ly), normal: normal, uv: vec2(1, 1)))
    
    meshes[(width, height, vSectors, hSectors)] = newMesh(vertexes)


proc newPlane(width, height: float32, v, h: int): Mesh =
    if not meshes.hasKey((width, height, v, h)):
        createPlaneMesh(width, height, v, h)
    result = meshes[(width, height, v, h)]
]#

proc newPlane(width, height: float32): Mesh =
    if not meshes.hasKey((width, height, 1, 1)):
        createPlaneMesh(width, height)
    result = meshes[(width, height, 1, 1)]

proc newPlaneMesh*(width, height: float32): MeshComponent = 
    var instance = newPlane(width, height)
    result = newMeshComponent(instance)
