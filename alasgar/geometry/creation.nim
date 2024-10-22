import ../core

type
    Shape* = object
        vertices: seq[Vertex]
        indices: seq[uint32]
    Extent* = object
        width*, height*, depth*: float32

proc `size`*(shape: Shape): uint32 = len(shape.indices).uint32

proc `$`*(c: Shape): string = 
    if len(c.indices) > 3 * 1024 * 1024:
        &"[{len(c.indices) div 3 div 1024 div 1024}m] triangles" 
    elif len(c.indices) > 3 * 1024: 
        &"[{len(c.indices) div 3 div 1024}k] triangles" 
    else: 
        &"[{len(c.indices) div 3}] triangles"

proc toMesh*(shape: var Shape): Mesh = newMesh(shape.vertices, shape.indices)

proc translate*(shape: var Shape, v: Vec3) =
    for i in 0..<len(shape.vertices):
        shape.vertices[i].position = shape.vertices[i].position + v

proc scale*(shape: var Shape, v: Vec3) =
    for i in 0..<len(shape.vertices):
        shape.vertices[i].position = shape.vertices[i].position * v

proc rotate*(shape: var Shape, axis: Vec3) =
    let rotation = euler(axis)# * mat4(1.0)
    for i in 0..<len(shape.vertices):
        echo shape.vertices[i].position, " * ", rotation, " = ", shape.vertices[i].position * rotation
        shape.vertices[i].position = shape.vertices[i].position * rotation

proc concate*(a, b: Shape): Shape =
    result.vertices = a.vertices & b.vertices
    result.indices = a.indices
    let offset = len(a.vertices).uint32
    for i in b.indices:
        add(result.indices, i + offset)

proc add*(shape: var Shape, vertices: openArray[Vertex], indices: openArray[uint32]) =
    let offset = len(shape.vertices).uint32
    add(shape.vertices, vertices)
    for i in indices:
        add(shape.indices, i + offset)

proc connect*(shape: var Shape, other: Shape) = add(shape, other.vertices, other.indices)

proc box*(extent: Extent, uvOffset=vec2(0.0), uvScale=vec2(1.0, 1.0)): Shape =
    let 
        width = extent.width
        height = extent.height
        depth = extent.depth

    add(result.vertices, [
       newVertex(position=vec3(-width / 2, -height / 2,  depth / 2), uv0=uvOffset + vec2(0, 0) * uvScale, normal=vec3( 0,  0,  1)),
       newVertex(position=vec3( width / 2, -height / 2,  depth / 2), uv0=uvOffset + vec2(1, 0) * uvScale, normal=vec3( 0,  0,  1)),
       newVertex(position=vec3( width / 2,  height / 2,  depth / 2), uv0=uvOffset + vec2(1, 1) * uvScale, normal=vec3( 0,  0,  1)),
       newVertex(position=vec3(-width / 2,  height / 2,  depth / 2), uv0=uvOffset + vec2(0, 1) * uvScale, normal=vec3( 0,  0,  1)), 
       # Back
       newVertex(position=vec3(-width / 2, -height / 2, -depth / 2), uv0=uvOffset + vec2(1, 0) * uvScale, normal=vec3( 0,  0, -1)),
       newVertex(position=vec3(-width / 2,  height / 2, -depth / 2), uv0=uvOffset + vec2(1, 1) * uvScale, normal=vec3( 0,  0, -1)),
       newVertex(position=vec3( width / 2,  height / 2, -depth / 2), uv0=uvOffset + vec2(0, 1) * uvScale, normal=vec3( 0,  0, -1)),
       newVertex(position=vec3( width / 2, -height / 2, -depth / 2), uv0=uvOffset + vec2(0, 0) * uvScale, normal=vec3( 0,  0, -1)),
       # Top
       newVertex(position=vec3(-width / 2,  height / 2, -depth / 2), uv0=uvOffset + vec2(0, 1) * uvScale, normal=vec3( 0,  1,  0)),
       newVertex(position=vec3(-width / 2,  height / 2,  depth / 2), uv0=uvOffset + vec2(0, 0) * uvScale, normal=vec3( 0,  1,  0)),
       newVertex(position=vec3( width / 2,  height / 2,  depth / 2), uv0=uvOffset + vec2(1, 0) * uvScale, normal=vec3( 0,  1,  0)),
       newVertex(position=vec3( width / 2,  height / 2, -depth / 2), uv0=uvOffset + vec2(1, 1) * uvScale, normal=vec3( 0,  1,  0)),
       # Bottom
       newVertex(position=vec3(-width / 2, -height / 2, -depth / 2), uv0=uvOffset + vec2(0, 0) * uvScale, normal=vec3( 0, -1,  0)), 
       newVertex(position=vec3( width / 2, -height / 2, -depth / 2), uv0=uvOffset + vec2(1, 0) * uvScale, normal=vec3( 0, -1,  0)),
       newVertex(position=vec3( width / 2, -height / 2,  depth / 2), uv0=uvOffset + vec2(1, 1) * uvScale, normal=vec3( 0, -1,  0)),
       newVertex(position=vec3(-width / 2, -height / 2,  depth / 2), uv0=uvOffset + vec2(0, 1) * uvScale, normal=vec3( 0, -1,  0)),
       # Right
       newVertex(position=vec3( width / 2, -height / 2, -depth / 2), uv0=uvOffset + vec2(1, 0) * uvScale, normal=vec3( 1,  0,  0)),
       newVertex(position=vec3( width / 2,  height / 2, -depth / 2), uv0=uvOffset + vec2(1, 1) * uvScale, normal=vec3( 1,  0,  0)), 
       newVertex(position=vec3( width / 2,  height / 2,  depth / 2), uv0=uvOffset + vec2(0, 1) * uvScale, normal=vec3( 1,  0,  0)),
       newVertex(position=vec3( width / 2, -height / 2,  depth / 2), uv0=uvOffset + vec2(0, 0) * uvScale, normal=vec3( 1,  0,  0)),
       # Left
       newVertex(position=vec3(-width / 2, -height / 2, -depth / 2), uv0=uvOffset + vec2(0, 0) * uvScale, normal=vec3(-1,  0,  0)),
       newVertex(position=vec3(-width / 2, -height / 2,  depth / 2), uv0=uvOffset + vec2(1, 0) * uvScale, normal=vec3(-1,  0,  0)),
       newVertex(position=vec3(-width / 2,  height / 2,  depth / 2), uv0=uvOffset + vec2(1, 1) * uvScale, normal=vec3(-1,  0,  0)),
       newVertex(position=vec3(-width / 2,  height / 2, -depth / 2), uv0=uvOffset + vec2(0, 1) * uvScale, normal=vec3(-1,  0,  0))
    ])
    add(result.indices, [
        0.uint32,  1,  2,  0,  2,  3,       # front
        4,  5,  6,  4,  6,  7,              # back
        8,  9,  10, 8,  10, 11,             # top
        12, 13, 14, 12, 14, 15,             # bottom
        16, 17, 18, 16, 18, 19,             # right
        20, 21, 22, 20, 22, 23,             # left
    ])

proc plane*(extent: Extent, uvOffset=vec2(0.0), uvScale=vec2(1.0, 1.0)): Shape =
    add(result.vertices, [
        newVertex(position=vec3(-0.5, 0.0, 0.5), normal=VEC3_UP, uv0=uvOffset + vec2(0, 0) * uvScale),
        newVertex(position=vec3(-0.5, 0, -0.5), normal=VEC3_UP, uv0=uvOffset + vec2(0, 1) * uvScale),
        newVertex(position=vec3(0.5, 0, -0.5), normal=VEC3_UP, uv0=uvOffset + vec2(1, 1) * uvScale),
        newVertex(position=vec3(0.5, 0, 0.5), normal=VEC3_UP, uv0=uvOffset + vec2(1, 0) * uvScale),
    ])
    add(result.indices, [
        0.uint32, 1, 2,
        0, 2, 3
    ])
    if extent.width != 1.0 or extent.depth != 1.0:
        scale(result, vec3(extent.width, 1.0, extent.depth))



