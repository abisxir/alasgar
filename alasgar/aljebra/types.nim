import strformat

type 
    Vec2* = object
        x*: float32
        y*: float32
    
    IVec2* = object
        x*: int32
        y*: int32

    UVec2* = object
        x*: uint32
        y*: uint32
    
    Vec3* = object
        x*: float32
        y*: float32
        z*: float32

    IVec3* = object
        x*: int32
        y*: int32
        z*: int32

    UVec3* = object
        x*: uint32
        y*: uint32
        z*: uint32

    Vec4* = object
        x*: float32
        y*: float32
        z*: float32
        w*: float32

    IVec4* = object
        x*: int32
        y*: int32
        z*: int32
        w*: int32

    UVec4* = object
        x*: uint32
        y*: uint32
        z*: uint32
        w*: uint32

    Quat* = object
        x*: float32
        y*: float32
        z*: float32
        w*: float32

    Mat3* = tuple
        m00: float32
        m01: float32
        m02: float32
        m10: float32
        m11: float32
        m12: float32
        m20: float32
        m21: float32
        m22: float32
        
    Mat4* = tuple
        m00: float32
        m01: float32
        m02: float32
        m03: float32
        m10: float32
        m11: float32
        m12: float32
        m13: float32
        m20: float32
        m21: float32
        m22: float32
        m23: float32
        m30: float32
        m31: float32
        m32: float32
        m33: float32

func caddr*[T:Vec2|IVec2|UVec2|Vec3|IVec3|UVec3|Vec4|IVec4|UVec4](v: var T): ptr float32 = v.x.addr
func caddr*[T:Mat3|Mat4](v: var T): ptr float32 = v[0].addr
func `$`*(a: Vec2): string = &"({a.x:.4f}, {a.y:.4f})"
func `$`*(a: Vec3): string = &"({a.x:.4f}, {a.y:.4f}, {a.z:.4f})"
func `$`*(a: Vec4): string = &"({a.x:.4f}, {a.y:.4f}, {a.z:.4f}, {a.w:.4f})"
func `$`*(a: Mat3): string = &"""[{a[0]:.5f}, {a[1]:.5f}, {a[2]:.5f},
{a[3]:.5f}, {a[4]:.5f}, {a[5]:.5f},
{a[6]:.5f}, {a[7]:.5f}, {a[8]:.5f}]"""
func `$`*(a: Mat4): string = &"""[{a[0]:.5f}, {a[1]:.5f}, {a[2]:.5f}, {a[3]:.5f},
{a[4]:.5f}, {a[5]:.5f}, {a[6]:.5f}, {a[7]:.5f},
{a[8]:.5f}, {a[9]:.5f}, {a[10]:.5f}, {a[11]:.5f},
{a[12]:.5f}, {a[13]:.5f}, {a[14]:.5f}, {a[15]:.5f}]"""