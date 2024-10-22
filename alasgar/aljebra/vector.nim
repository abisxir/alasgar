import helpers
import types

export helpers, types

# Vec2
func vec2*(x, y: float32): Vec2 = Vec2(x: x, y: y)
func ivec2*(x, y: int32): IVec2 = IVec2(x: x, y: y)
func uvec2*(x, y: uint32): UVec2 = UVec2(x: x, y: y)
func vec2*(a: Vec2): Vec2 = Vec2(x: a.x, y: a.y)
func ivec2*(a: IVec2): IVec2 = IVec2(x: a.x, y: a.y)
func uvec2*(a: UVec2): UVec2 = UVec2(x: a.x, y: a.y)
func vec2*(x: float32): Vec2 = vec2(x, x)
func ivec2*(x: int32): IVec2 = ivec2(x, x)
func uvec2*(x: uint32): UVec2 = uvec2(x, x)
func vec2*(a: IVec2): Vec2 = Vec2(x: a.x.float32, y: a.y.float32)
func vec2*(a: UVec2): Vec2 = Vec2(x: a.x.float32, y: a.y.float32)
func ivec2*(a: Vec2): IVec2 = IVec2(x: a.x.int32, y: a.y.int32)
func ivec2*(a: UVec2): IVec2 = IVec2(x: a.x.int32, y: a.y.int32)
func uvec2*(a: Vec2): UVec2 = UVec2(x: a.x.uint32, y: a.y.uint32)
func uvec2*(a: IVec2): UVec2 = UVec2(x: a.x.uint32, y: a.y.uint32)
func vec2*(v: array[2, float32]): Vec2 = vec2(v[0], v[1])
func vec2*(v: openArray[float32], offset: int): Vec2 = vec2(v[offset], v[offset + 1])
func `+`*[T: Vec2|IVec2|UVec2](a, b: T): T = T(x: a.x + b.x, y: a.y + b.y)
func `+`*[T: Vec2, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.float32, y: a.y + f.float32)
func `+`*[T: IVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.int32, y: a.y + f.int32)
func `+`*[T: UVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.uint32, y: a.y + f.uint32)
func `+`*[T: Vec2, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.float32, y: a.y + f.float32)
func `+`*[T: IVec2, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.int32, y: a.y + f.int32)
func `+`*[T: UVec2, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.uint32, y: a.y + f.uint32)
func `-`*[T: Vec2|IVec2|UVec2](a, b: T): T = T(x: a.x - b.x, y: a.y - b.y)
func `-`*[T: Vec2, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.float32, y: a.y - f.float32)
func `-`*[T: IVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.int32, y: a.y - f.int32)
func `-`*[T: UVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.uint32, y: a.y - f.uint32)
func `-`*[T: Vec2, F: float|int|uint](f: F, a: T): T = T(x: f.float32 - a.x, y: f.float32 - a.y)
func `-`*[T: IVec2, F: float|int|uint](f: F, a: T): T = T(x: f.int32 - a.x, y: f.int32 - a.y)
func `-`*[T: UVec2, F: float|int|uint](f: F, a: T): T = T(x: f.uint32 - a.x, y: f.uint32 - a.y)
func `*`*[T: Vec2|IVec2|UVec2](a, b: T): T = T(x: a.x * b.x, y: a.y * b.y)
func `*`*[T: Vec2, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.float32, y: a.y * f.float32)
func `*`*[T: IVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.int32, y: a.y * f.int32)
func `*`*[T: UVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.uint32, y: a.y * f.uint32)
func `*`*[T: Vec2, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.float32, y: a.y * f.float32)
func `*`*[T: IVec2, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.int32, y: a.y * f.int32)
func `*`*[T: UVec2, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.uint32, y: a.y * f.uint32)
func `/`*[T: Vec2|IVec2|UVec2](a, b: T): T = T(x: a.x / b.x, y: a.y / b.y)
func `/`*[T: Vec2, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.float32, y: a.y / f.float32)
func `/`*[T: IVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.int32, y: a.y / f.int32)
func `/`*[T: UVec2, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.uint32, y: a.y / f.uint32)
func `/`*[T: Vec2, F: float|int|uint](f: F, a: T): T = T(x: f.float32 / a.x, y: f.float32 / a.y)
func `/`*[T: IVec2, F: float|int|uint](f: F, a: T): T = T(x: f.float32 / a.x, y: f.float32 / a.y)
func `/`*[T: UVec2, F: float|int|uint](f: F, a: T): T = T(x: f.float32 / a.x, y: f.float32 / a.y)

func `+=`*[T: Vec2|IVec2|UVec2](a: var T, b: T) = 
    a.x += b.x
    a.y += b.y
func `+=`*[T: Vec2, F: float|int|uint](a: var T, f: F) = 
    a.x += f.float32
    a.y += f.float32
func `+=`*[T: IVec2, F: float|int|uint](a: var T, f: F) = 
    a.x += f.int32
    a.y += f.int32
func `+=`*[T: UVec2, F: float|int|uint](a: var T, f: F) = 
    a.x += f.uint32
    a.y += f.uint32

func `-=`*[T: Vec2|IVec2|UVec2](a: var T, b: T) = 
    a.x -= b.x
    a.y -= b.y
func `-=`*[T: Vec2, F: float|int|uint](a: var T, f: F) = 
    a.x -= f.float32
    a.y -= f.float32
func `-=`*[T: IVec2, F: float|int|uint](a: var T, f: F) = 
    a.x -= f.int32
    a.y -= f.int32
func `-=`*[T: UVec2, F: float|int|uint](a: var T, f: F) = 
    a.x -= f.uint32
    a.y -= f.uint32

func `*=`*[T: Vec2|IVec2|UVec2](a: var T, b: T) = 
    a.x *= b.x
    a.y *= b.y
func `*=`*[T: Vec2, F: float|int|uint](a: var T, f: F) = 
    a.x *= f.float32
    a.y *= f.float32
func `*=`*[T: IVec2, F: float|int|uint](a: var T, f: F) = 
    a.x *= f.int32
    a.y *= f.int32
func `*=`*[T: UVec2, F: float|int|uint](a: var T, f: F) = 
    a.x *= f.uint32
    a.y *= f.uint32

func `/=`*[T: Vec2|IVec2|UVec2](a: var T, b: T) = 
    a.x /= b.x
    a.y /= b.y
func `/=`*[T: Vec2, F: float|int|uint](a: var T, f: F) = 
    a.x /= f.float32
    a.y /= f.float32
func `/=`*[T: IVec2, F: float|int|uint](a: var T, f: F) = 
    a.x /= f.int32
    a.y /= f.int32
func `/=`*[T: UVec2, F: float|int|uint](a: var T, f: F) = 
    a.x /= f.uint32
    a.y /= f.uint32

func hash*[T: Vec2|IVec2|UVec2](a: T): Hash = hash((a.x, a.y))

func lengthSq*(a: Vec2): float32 = a.x * a.x + a.y * a.y 
func lengthSq*(a: IVec2): int32 = a.x * a.x + a.y * a.y 
func lengthSq*(a: UVec2): uint32 = a.x * a.x + a.y * a.y 
func dot*(a, b: Vec2): float32 = a.x * b.x + a.y * b.y 
func dot*(a, b: IVec2): int32 = a.x * b.x + a.y * b.y 
func dot*(a, b: UVec2): uint32 = a.x * b.x + a.y * b.y 
func floor*(a: Vec2): Vec2 = vec2(floor(a.x), floor(a.y))
func floor*(a: IVec2): IVec2 = a
func floor*(a: UVec2): UVec2 = a
func round*(a: Vec2): Vec2 = vec2(round(a.x), round(a.y))
func round*(a: IVec2): IVec2 = a
func round*(a: UVec2): UVec2 = a
func ceil*(a: Vec2): Vec2 = vec2(ceil(a.x), ceil(a.y))
func ceil*(a: IVec2): IVec2 = a
func ceil*(a: UVec2): UVec2 = a
func cross*(a, b: Vec2): float32 = a.x * b.y - b.x * a.y
func clamp*(v, a, b: Vec2): Vec2 = Vec2(x: clamp(v.x, a.x, b.x), y: clamp(v.y, a.y, b.y))
func min*(v1, v2: Vec2): Vec2 = vec2(min(v1.x, v2.x), min(v1.y, v2.y))
func max*(v1, v2: Vec2): Vec2 = vec2(max(v1.x, v2.x), max(v1.y, v2.y))


func quantize*(v: Vec2, n: float32): Vec2 =
    result.x = sgn(v.x).float32 * floor(abs(v.x) / n) * n
    result.y = sgn(v.y).float32 * floor(abs(v.y) / n) * n

func almostEquals*(a, b: Vec2): bool =
    let c = a - b
    abs(c.x) < EPSILON and abs(c.y) < EPSILON

func `[]`*(a: Vec2, i: int): float32 =
    if i == 0:
        return a.x
    elif i == 1:
        return a.y

func `[]`*(a: IVec2, i: int): int32 =
    if i == 0:
        return a.x
    elif i == 1:
        return a.y    

func `[]`*(a: UVec2, i: int): uint32 =
    if i == 0:
        return a.x
    elif i == 1:
        return a.y    

func `[]=`*(a: var Vec2, i: int, b: float32) =
    if i == 0:
        a.x = b
    elif i == 1:
        a.y = b

func `[]=`*(a: var IVec2, i: int, b: int32) =
    if i == 0:
        a.x = b
    elif i == 1:
        a.y = b

func `[]=`*(a: var UVec2, i: int, b: uint32) =
    if i == 0:
        a.x = b
    elif i == 1:
        a.y = b

# Vec3
func vec3*(x, y, z: float32): Vec3 = Vec3(x: x, y: y, z: z)
func ivec3*(x, y, z: int32): IVec3 = IVec3(x: x, y: y, z: z)
func uvec3*(x, y, z: uint32): UVec3 = UVec3(x: x, y: y, z: z)
func vec3*(a: Vec3): Vec3 = Vec3(x: a.x, y: a.y, z: a.z)
func ivec3*(a: IVec3): IVec3 = IVec3(x: a.x, y: a.y, z: a.z)
func uvec3*(a: UVec3): UVec3 = UVec3(x: a.x, y: a.y, z: a.z)
func vec3*(x: float32): Vec3 = vec3(x, x, x)
func ivec3*(x: int32): IVec3 = ivec3(x, x, x)
func uvec3*(x: uint32): UVec3 = uvec3(x, x, x)
func vec3*(a: IVec3): Vec3 = Vec3(x: a.x.float32, y: a.y.float32, z: a.z.float32)
func vec3*(a: UVec3): Vec3 = Vec3(x: a.x.float32, y: a.y.float32, z: a.z.float32)
func ivec3*(a: Vec3): IVec3 = IVec3(x: a.x.int32, y: a.y.int32, z: a.z.int32)
func ivec3*(a: UVec3): IVec3 = IVec3(x: a.x.int32, y: a.y.int32, z: a.z.int32)
func uvec3*(a: Vec3): UVec3 = UVec3(x: a.x.uint32, y: a.y.uint32, z: a.z.uint32)
func uvec3*(a: IVec3): UVec3 = UVec3(x: a.x.uint32, y: a.y.uint32, z: a.z.uint32)
func vec3*(v: array[3, float32]): Vec3 = vec3(v[0], v[1], v[2])
func vec3*(v: openArray[float32], offset: int): Vec3 = vec3(v[offset], v[offset + 1], v[offset + 2])
func `+`*[T: Vec3|IVec3|UVec3](a, b: T): T = T(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z)
func `+`*[T: Vec3, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.float32, y: a.y + f.float32, z: a.z + f.float32)
func `+`*[T: IVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.int32, y: a.y + f.int32, z: a.z + f.int32)
func `+`*[T: UVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.uint32, y: a.y + f.uint32, z: a.z + f.uint32)
func `+`*[T: Vec3, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.float32, y: a.y + f.float32, z: a.z + f.float32)
func `+`*[T: IVec3, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.int32, y: a.y + f.int32, z: a.z + f.int32)
func `+`*[T: UVec3, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.uint32, y: a.y + f.uint32, z: a.z + f.uint32)
func `-`*[T: Vec3|IVec3|UVec3](a, b: T): T = T(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z)
func `-`*[T: Vec3, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.float32, y: a.y - f.float32, z: a.z - f.float32)
func `-`*[T: IVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.int32, y: a.y - f.int32, z: a.z - f.int32)
func `-`*[T: UVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.uint32, y: a.y - f.uint32, z: a.z - f.uint32)
func `-`*[T: Vec3, F: float|int|uint](f: F, a: T): T = T(x: f.float32 - a.x, y: f.float32 - a.y, z: f.float32 - a.z)
func `-`*[T: IVec3, F: float|int|uint](f: F, a: T): T = T(x: f.int32 - a.x, y: f.int32 - a.y, z: f.int32 - a.z)
func `-`*[T: UVec3, F: float|int|uint](f: F, a: T): T = T(x: f.uint32 - a.x, y: f.uint32 - a.y, z: f.uint32 - a.z)
func `*`*[T: Vec3|IVec3|UVec3](a, b: T): T = T(x: a.x * b.x, y: a.y * b.y, z: a.z * b.z)
func `*`*[T: Vec3, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.float32, y: a.y * f.float32, z: a.z * f.float32)
func `*`*[T: IVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.int32, y: a.y * f.int32, z: a.z * f.int32)
func `*`*[T: UVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.uint32, y: a.y * f.uint32, z: a.z * f.uint32)
func `*`*[T: Vec3, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.float32, y: a.y * f.float32, z: a.z * f.float32)
func `*`*[T: IVec3, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.int32, y: a.y * f.int32, z: a.z * f.int32)
func `*`*[T: UVec3, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.uint32, y: a.y * f.uint32, z: a.z * f.uint32)
func `/`*[T: Vec3|IVec3|UVec3](a, b: T): T = T(x: a.x / b.x, y: a.y / b.y, z: a.z / b.z)
func `/`*[T: Vec3, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.float32, y: a.y / f.float32, z: a.z / f.float32)
func `/`*[T: IVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.int32, y: a.y / f.int32, z: a.z / f.int32)
func `/`*[T: UVec3, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.uint32, y: a.y / f.uint32, z: a.z / f.uint32)
func `/`*[T: Vec3, F: float|int|uint](f: F, a: T): T = T(x: f.float32 / a.x, y: f.float32 / a.y, z: f.float32 / a.z)
func `/`*[T: IVec3, F: float|int|uint](f: F, a: T): T = T(x: f.int32 / a.x, y: f.int32 / a.y, z: f.int32 / a.z)
func `/`*[T: UVec3, F: float|int|uint](f: F, a: T): T = T(x: f.uint32 / a.x, y: f.uint32 / a.y, z: f.uint32 / a.z)

func `+=`*[T: Vec3|IVec3|UVec3](a: var T, b: T) = 
    a.x += b.x
    a.y += b.y
    a.z += b.z
func `+=`*[T: Vec3, F: float|int|uint](a: var T, f: F) = 
    a.x += f.float32
    a.y += f.float32
    a.z += f.float32
func `+=`*[T: IVec3, F: float|int|uint](a: var T, f: F) = 
    a.x += f.int32
    a.y += f.int32
    a.z += f.int32
func `+=`*[T: UVec3, F: float|int|uint](a: var T, f: F) = 
    a.x += f.uint32
    a.y += f.uint32
    a.z += f.uint32

func `-=`*[T: Vec3|IVec3|UVec3](a: var T, b: T) = 
    a.x -= b.x
    a.y -= b.y
    a.z -= b.z
func `-=`*[T: Vec3, F: float|int|uint](a: var T, f: F) = 
    a.x -= f.float32
    a.y -= f.float32
    a.z -= f.float32
func `-=`*[T: IVec3, F: float|int|uint](a: var T, f: F) = 
    a.x -= f.int32
    a.y -= f.int32
    a.z -= f.int32
func `-=`*[T: UVec3, F: float|int|uint](a: var T, f: F) = 
    a.x -= f.uint32
    a.y -= f.uint32
    a.z -= f.uint32

func `*=`*[T: Vec3|IVec3|UVec3](a: var T, b: T) = 
    a.x *= b.x
    a.y *= b.y
    a.z *= b.z
func `*=`*[T: Vec3, F: float|int|uint](a: var T, f: F) = 
    a.x *= f.float32
    a.y *= f.float32
    a.z *= f.float32
func `*=`*[T: IVec3, F: float|int|uint](a: var T, f: F) = 
    a.x *= f.int32
    a.y *= f.int32
    a.z *= f.int32
func `*=`*[T: UVec3, F: float|int|uint](a: var T, f: F) = 
    a.x *= f.uint32
    a.y *= f.uint32
    a.z *= f.uint32

func `/=`*[T: Vec3|IVec3|UVec3](a: var T, b: T) = 
    a.x /= b.x
    a.y /= b.y
    a.z /= b.z
func `/=`*[T: Vec3, F: float|int|uint](a: var T, f: F) = 
    a.x /= f.float32
    a.y /= f.float32
    a.z /= f.float32
func `/=`*[T: IVec3, F: float|int|uint](a: var T, f: F) = 
    a.x /= f.int32
    a.y /= f.int32
    a.z /= f.int32
func `/=`*[T: UVec3, F: float|int|uint](a: var T, f: F) = 
    a.x /= f.uint32
    a.y /= f.uint32
    a.z /= f.uint32

func hash*[T: Vec3|IVec3|UVec3](a: T): Hash = hash((a.x, a.y, a.z))

func lengthSq*(a: Vec3): float32 = a.x * a.x + a.y * a.y + a.z * a.z
func lengthSq*(a: IVec3): int32 = a.x * a.x + a.y * a.y + a.z * a.z
func lengthSq*(a: UVec3): uint32 = a.x * a.x + a.y * a.y + a.z * a.z
func dot*(a, b: Vec3): float32 = a.x * b.x + a.y * b.y + a.z * b.z
func dot*(a, b: IVec3): int32 = a.x * b.x + a.y * b.y + a.z * b.z
func dot*(a, b: UVec3): uint32 = a.x * b.x + a.y * b.y + a.z * b.z
func floor*(a: Vec3): Vec3 = vec3(floor(a.x), floor(a.y), floor(a.z))
func floor*(a: IVec3): IVec3 = a
func floor*(a: UVec3): UVec3 = a
func round*(a: Vec3): Vec3 = vec3(round(a.x), round(a.y), round(a.z))
func round*(a: IVec3): IVec3 = a
func round*(a: UVec3): UVec3 = a
func ceil*(a: Vec3): Vec3 = vec3(ceil(a.x), ceil(a.y), ceil(a.z))
func ceil*(a: IVec3): IVec3 = a
func ceil*(a: UVec3): UVec3 = a
func cross*[T: Vec3|IVec3|UVec3](a, b: T): T = vec3(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x)
func clamp*(v, a, b: Vec3): Vec3 = Vec3(x: clamp(v.x, a.x, b.x), y: clamp(v.y, a.y, b.y), z: clamp(v.z, a.z, b.z))
func min*(v1, v2: Vec3): Vec3 = vec3(min(v1.x, v2.x), min(v1.y, v2.y), min(v1.z, v2.z))
func max*(v1, v2: Vec3): Vec3 = vec3(max(v1.x, v2.x), max(v1.y, v2.y), max(v1.z, v2.z))


func quantize*(v: Vec3, n: float32): Vec3 =
    result.x = sgn(v.x).float32 * floor(abs(v.x) / n) * n
    result.y = sgn(v.y).float32 * floor(abs(v.y) / n) * n
    result.z = sgn(v.z).float32 * floor(abs(v.z) / n) * n

func almostEquals*(a, b: Vec3): bool =
    let c = a - b
    abs(c.x) < EPSILON and abs(c.y) < EPSILON and abs(c.z) < EPSILON

func `[]`*(a: Vec3, i: int): float32 =
    if i == 0:
        return a.x
    elif i == 1:
        return a.y
    elif i == 2:
        return a.z

func `[]`*(a: IVec3, i: int): int32 =
    if i == 0:
        return a.x
    elif i == 1:
        return a.y
    elif i == 2:
        return a.z 

func `[]`*(a: UVec3, i: int): uint32 =
    if i == 0:
        return a.x
    elif i == 1:
        return a.y
    elif i == 2:
        return a.z   

func `[]=`*(a: var Vec3, i: int, b: float32) =
    if i == 0:
        a.x = b
    elif i == 1:
        a.y = b
    elif i == 2:
        a.z = b

func `[]=`*(a: var IVec3, i: int, b: int32) =
    if i == 0:
        a.x = b
    elif i == 1:
        a.y = b
    elif i == 2:
        a.z = b

func `[]=`*(a: var UVec3, i: int, b: uint32) =
    if i == 0:
        a.x = b
    elif i == 1:
        a.y = b
    elif i == 2:
        a.z = b

# Vec4
func vec4*(x, y, z, w: float32): Vec4 = Vec4(x: x, y: y, z: z, w: w)
func vec4*(xy: Vec2, z, w: float32): Vec4 = Vec4(x: xy.x, y: xy.y, z: z, w: w)
func ivec4*(x, y, z, w: int32): IVec4 = IVec4(x: x, y: y, z: z, w: w)
func uvec4*(x, y, z, w: uint32): UVec4 = UVec4(x: x, y: y, z: z, w: w)
func vec4*(a: Vec4): Vec4 = Vec4(x: a.x, y: a.y, z: a.z, w: a.w)
func ivec4*(a: IVec4): IVec4 = IVec4(x: a.x, y: a.y, z: a.z, w: a.w)
func uvec4*(a: UVec4): UVec4 = UVec4(x: a.x, y: a.y, z: a.z, w: a.w)
func vec4*(a: Vec3, f: float32): Vec4 = Vec4(x: a.x, y: a.y, z: a.z, w: f)
func ivec4*(a: IVec3, f: int32): IVec4 = IVec4(x: a.x, y: a.y, z: a.z, w: f)
func uvec4*(a: UVec3, f: uint32): UVec4 = UVec4(x: a.x, y: a.y, z: a.z, w: f)
func vec4*(x: float32): Vec4 = vec4(x, x, x, x)
func ivec4*(x: int32): IVec4 = ivec4(x, x, x, x)
func uvec4*(x: uint32): UVec4 = uvec4(x, x, x, x)
func vec4*(a: IVec4): Vec4 = Vec4(x: a.x.float32, y: a.y.float32, z: a.z.float32, w: a.w.float32)
func vec4*(a: UVec4): Vec4 = Vec4(x: a.x.float32, y: a.y.float32, z: a.z.float32, w: a.w.float32)
func ivec4*(a: Vec4): IVec4 = IVec4(x: a.x.int32, y: a.y.int32, z: a.z.int32, w: a.w.int32)
func ivec4*(a: UVec4): IVec4 = IVec4(x: a.x.int32, y: a.y.int32, z: a.z.int32, w: a.w.int32)
func uvec4*(a: Vec4): UVec4 = UVec4(x: a.x.uint32, y: a.y.uint32, z: a.z.uint32, w: a.w.uint32)
func uvec4*(a: IVec4): UVec4 = UVec4(x: a.x.uint32, y: a.y.uint32, z: a.z.uint32, w: a.w.uint32)
func vec4*(v: array[4, float32]): Vec4 = vec4(v[0], v[1], v[2], v[3])
func vec4*(v: openArray[float32], offset: int): Vec4 = vec4(v[offset], v[offset + 1], v[offset + 2], v[offset + 3])
func `+`*[T: Vec4|IVec4|UVec4](a, b: T): T = T(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z, w: a.w + b.w)
func `+`*[T: Vec4, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.float32, y: a.y + f.float32, z: a.z + f.float32, w: a.w + f.float32)
func `+`*[T: IVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.int32, y: a.y + f.int32, z: a.z + f.int32, w: a.w + f.int32)
func `+`*[T: UVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x + f.uint32, y: a.y + f.uint32, z: a.z + f.uint32, w: a.w + f.uint32)
func `+`*[T: Vec4, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.float32, y: a.y + f.float32, z: a.z + f.float32, w: a.w + f.float32)
func `+`*[T: IVec4, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.int32, y: a.y + f.int32, z: a.z + f.int32, w: a.w + f.int32)
func `+`*[T: UVec4, F: float|int|uint](f: F, a: T): T = T(x: a.x + f.uint32, y: a.y + f.uint32, z: a.z + f.uint32, w: a.w + f.uint32)
func `-`*[T: Vec4|IVec4|UVec4](a, b: T): T = T(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z, w: a.w - b.w)
func `-`*[T: Vec4, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.float32, y: a.y - f.float32, z: a.z - f.float32, w: a.w - f.float32)
func `-`*[T: IVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.int32, y: a.y - f.int32, z: a.z - f.int32, w: a.w - f.int32)
func `-`*[T: UVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x - f.uint32, y: a.y - f.uint32, z: a.z - f.uint32, w: a.w - f.uint32)
func `-`*[T: Vec4, F: float|int|uint](f: F, a: T): T = T(x: f.float32 - a.x, y: f.float32 - a.y, z: f.float32 - a.z, w: f.float32 - a.w)
func `-`*[T: IVec4, F: float|int|uint](f: F, a: T): T = T(x: f.int32 - a.x, y: f.int32 - a.y, z: f.int32 - a.z, w: f.int32 - a.w)
func `-`*[T: UVec4, F: float|int|uint](f: F, a: T): T = T(x: f.uint32 - a.x, y: f.uint32 - a.y, z: f.uint32 - a.z, w: f.uint32 - a.w)
func `*`*[T: Vec4|IVec4|UVec4](a, b: T): T = T(x: a.x * b.x, y: a.y * b.y, z: a.z * b.z, w: a.w * b.w)
func `*`*[T: Vec4, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.float32, y: a.y * f.float32, z: a.z * f.float32, w: a.w * f.float32)
func `*`*[T: IVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.int32, y: a.y * f.int32, z: a.z * f.int32, w: a.w * f.int32)
func `*`*[T: UVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x * f.uint32, y: a.y * f.uint32, z: a.z * f.uint32, w: a.w * f.uint32)
func `*`*[T: Vec4, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.float32, y: a.y * f.float32, z: a.z * f.float32, w: a.w * f.float32)
func `*`*[T: IVec4, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.int32, y: a.y * f.int32, z: a.z * f.int32, w: a.w * f.int32)
func `*`*[T: UVec4, F: float|int|uint](f: F, a: T): T = T(x: a.x * f.uint32, y: a.y * f.uint32, z: a.z * f.uint32, w: a.w * f.uint32)
func `/`*[T: Vec4|IVec4|UVec4](a, b: T): T = T(x: a.x / b.x, y: a.y / b.y, z: a.z / b.z, w: a.w / b.w)
func `/`*[T: Vec4, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.float32, y: a.y / f.float32, z: a.z / f.float32, w: a.w / f.float32)
func `/`*[T: IVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.int32, y: a.y / f.int32, z: a.z / f.int32, w: a.w / f.int32)
func `/`*[T: UVec4, F: float|int|uint](a: T, f: F): T = T(x: a.x / f.uint32, y: a.y / f.uint32, z: a.z / f.uint32, w: a.w / f.uint32)
func `/`*[T: Vec4, F: float|int|uint](f: F, a: T): T = T(x: f.float32 / a.x, y: f.float32 / a.y, z: f.float32 / a.z, w: f.float32 / a.w)
func `/`*[T: IVec4, F: float|int|uint](f: F, a: T): T = T(x: f.int32 / a.x, y: f.int32 / a.y, z: f.int32 / a.z, w: f.int32 / a.w)
func `/`*[T: UVec4, F: float|int|uint](f: F, a: T): T = T(x: f.uint32 / a.x, y: f.uint32 / a.y, z: f.uint32 / a.z, w: f.uint32 / a.w)

func `+=`*[T: Vec4|IVec4|UVec4](a: var T, b: T) = 
    a.x += b.x
    a.y += b.y
    a.z += b.z
    a.w += b.w
func `+=`*[T: Vec4, F: float|int|uint](a: var T, f: F) = 
    a.x += f.float32
    a.y += f.float32
    a.z += f.float32
    a.w += f.float32
func `+=`*[T: IVec4, F: float|int|uint](a: var T, f: F) = 
    a.x += f.int32
    a.y += f.int32
    a.z += f.int32
    a.w += f.int32
func `+=`*[T: UVec4, F: float|int|uint](a: var T, f: F) = 
    a.x += f.uint32
    a.y += f.uint32
    a.z += f.uint32
    a.w += f.uint32

func `-=`*[T: Vec4|IVec4|UVec4](a: var T, b: T) = 
    a.x -= b.x
    a.y -= b.y
    a.z -= b.z
    a.w -= b.w
func `-=`*[T: Vec4, F: float|int|uint](a: var T, f: F) = 
    a.x -= f.float32
    a.y -= f.float32
    a.z -= f.float32
    a.w -= f.float32
func `-=`*[T: IVec4, F: float|int|uint](a: var T, f: F) = 
    a.x -= f.int32
    a.y -= f.int32
    a.z -= f.int32
    a.w -= f.int32
func `-=`*[T: UVec4, F: float|int|uint](a: var T, f: F) = 
    a.x -= f.uint32
    a.y -= f.uint32
    a.z -= f.uint32
    a.w -= f.uint32

func `*=`*[T: Vec4|IVec4|UVec4](a: var T, b: T) = 
    a.x *= b.x
    a.y *= b.y
    a.z *= b.z
    a.w *= b.w
func `*=`*[T: Vec4, F: float|int|uint](a: var T, f: F) = 
    a.x *= f.float32
    a.y *= f.float32
    a.z *= f.float32
    a.w *= f.float32
func `*=`*[T: IVec4, F: float|int|uint](a: var T, f: F) = 
    a.x *= f.int32
    a.y *= f.int32
    a.z *= f.int32
    a.w *= f.int32
func `*=`*[T: UVec4, F: float|int|uint](a: var T, f: F) = 
    a.x *= f.uint32
    a.y *= f.uint32
    a.z *= f.uint32
    a.w *= f.uint32

func `/=`*[T: Vec4|IVec4|UVec4](a: var T, b: T) = 
    a.x /= b.x
    a.y /= b.y
    a.z /= b.z
    a.w /= b.w
func `/=`*[T: Vec4, F: float|int|uint](a: var T, f: F) = 
    a.x /= f.float32
    a.y /= f.float32
    a.z /= f.float32
    a.w /= f.float32
func `/=`*[T: IVec4, F: float|int|uint](a: var T, f: F) = 
    a.x /= f.int32
    a.y /= f.int32
    a.z /= f.int32
    a.w /= f.int32
func `/=`*[T: UVec4, F: float|int|uint](a: var T, f: F) = 
    a.x /= f.uint32
    a.y /= f.uint32
    a.z /= f.uint32
    a.w /= f.uint32

func hash*[T: Vec4|IVec4|UVec4](a: T): Hash = hash((a.x, a.y, a.z, a.w))

func lengthSq*(a: Vec4): float32 = a.x * a.x + a.y * a.y + a.z * a.z + a.w * a.w
func lengthSq*(a: IVec4): int32 = a.x * a.x + a.y * a.y + a.z * a.z + a.w * a.w
func lengthSq*(a: UVec4): uint32 = a.x * a.x + a.y * a.y + a.z * a.z + a.w * a.w
func dot*(a, b: Vec4): float32 = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
func dot*(a, b: IVec4): int32 = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
func dot*(a, b: UVec4): uint32 = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
func floor*(a: Vec4): Vec4 = vec4(floor(a.x), floor(a.y), floor(a.z), floor(a.w))
func floor*(a: IVec4): IVec4 = a
func floor*(a: UVec4): UVec4 = a
func round*(a: Vec4): Vec4 = vec4(round(a.x), round(a.y), round(a.z), floor(a.w))
func round*(a: IVec4): IVec4 = a
func round*(a: UVec4): UVec4 = a
func ceil*(a: Vec4): Vec4 = vec4(ceil(a.x), ceil(a.y), ceil(a.z), ceil(a.w))
func ceil*(a: IVec4): IVec4 = a
func ceil*(a: UVec4): UVec4 = a
func cross*[T: Vec4|IVec4|UVec4](a, b: T): T = vec4(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x, 0)
func clamp*(v, a, b: Vec4): Vec4 = Vec4(x: clamp(v.x, a.x, b.x), y: clamp(v.y, a.y, b.y), z: clamp(v.z, a.z, b.z), w: clamp(v.w, a.w, b.w))
func min*(v1, v2: Vec4): Vec4 = vec4(min(v1.x, v2.x), min(v1.y, v2.y), min(v1.z, v2.z), min(v1.w, v2.w))
func max*(v1, v2: Vec4): Vec4 = vec4(max(v1.x, v2.x), max(v1.y, v2.y), max(v1.z, v2.z), max(v1.w, v2.w))


func quantize*(v: Vec4, n: float32): Vec4 =
    result.x = sgn(v.x).float32 * floor(abs(v.x) / n) * n
    result.y = sgn(v.y).float32 * floor(abs(v.y) / n) * n
    result.z = sgn(v.z).float32 * floor(abs(v.z) / n) * n
    result.w = sgn(v.w).float32 * floor(abs(v.w) / n) * n

func almostEquals*(a, b: Vec4): bool =
    let c = a - b
    abs(c.x) < EPSILON and abs(c.y) < EPSILON and abs(c.z) < EPSILON and abs(c.w) < EPSILON

func `[]`*(a: Vec4, i: int): float32 =
    if i == 0:
        return a.x
    elif i == 1:
        return a.y
    elif i == 2:
        return a.z
    elif i == 3:
        return a.w

func `[]`*(a: IVec4, i: int): int32 =
    if i == 0:
        return a.x
    elif i == 1:
        return a.y
    elif i == 2:
        return a.z 
    elif i == 3:
        return a.w

func `[]`*(a: UVec4, i: int): uint32 =
    if i == 0:
        return a.x
    elif i == 1:
        return a.y
    elif i == 2:
        return a.z   
    elif i == 3:
        return a.w

func `[]=`*(a: var Vec4, i: int, b: float32) =
    if i == 0:
        a.x = b
    elif i == 1:
        a.y = b
    elif i == 2:
        a.z = b
    elif i == 3:
        a.w = b

func `[]=`*(a: var IVec4, i: int, b: int32) =
    if i == 0:
        a.x = b
    elif i == 1:
        a.y = b
    elif i == 2:
        a.z = b
    elif i == 3:
        a.w = b

func `[]=`*(a: var UVec4, i: int, b: uint32) =
    if i == 0:
        a.x = b
    elif i == 1:
        a.y = b
    elif i == 2:
        a.z = b
    elif i == 3:
        a.w = b

# All
func `-`*[T:Vec2|IVec2|UVec2|Vec3|IVec3|UVec3|Vec4|IVec4|UVec4](a: T): T = -1 * a
func length*[T:Vec2|Vec3|Vec4](a: T): float32 = sqrt(lengthSq(a))
func distance*[T:Vec2|IVec2|UVec2|Vec3|IVec3|UVec3|Vec4|IVec4|UVec4](at, to: T): float32 = length(at - to).float32
func distanceSq*[T:Vec2|IVec2|UVec2|Vec3|IVec3|UVec3|Vec4|IVec4|UVec4](at, to: T): float32 = lengthSq(at - to).float32
func lerp*[T:Vec2|Vec3|Vec4](a, b: T, v: float32): T = a * (1 - v) + b * v
func lerp*[T:IVec2|IVec3|IVec4](a, b: T, v: int32): T = a * (1 - v) + b * v
func lerp*[T:UVec2|UVec3|UVec4](a, b: T, v: uint32): T = a * (1 - v) + b * v
func clamp[T:Vec2|IVec2|UVec2|Vec3|IVec3|UVec3|Vec4|IVec4|UVec4](a, b, c: T): T =
    if a < b:
        result = b
    elif a > c:
        result = c
func saturate*(v: float): float = clamp(v, EPSILON, 1.0)
func saturate*(v: Vec2): Vec2 = clamp(v, vec2(EPSILON), vec2(1.0))
func saturate*(v: Vec3): Vec3 = clamp(v, vec3(EPSILON), vec3(1.0))
func saturate*(v: Vec4): Vec4 = clamp(v, vec4(EPSILON), vec4(1.0))
func mix*[T:Vec2|Vec3|Vec4](a, b: T, v: float32): T = v * (b - a) + a
func mix*(a, b, v: float32): float32 = v * (b - a) + a

func step*(edge, x: float32): float32 =
    if x < edge:
        0.0
    else:
        1.0

func normalize*[T:Vec2|Vec3|Vec4](a: T): T = 
    let l = length(a)
    if l != 0:
        result = a / l

func dir*[T:Vec2|Vec3|Vec4](at, to: T): T = normalize(at - to)

func angle*[T: Vec2|Vec3|Vec4](a, b: T): float32 =
    let 
        magA = length(a)
        magB = length(b)
    if magA != 0 and magB != 0:
        let cosTheta = dot(a, b) / (magA * magB)
        result = arccos(clamp(cosTheta, -1.0, 1.0))

