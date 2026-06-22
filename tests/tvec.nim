import std/unittest

import ../private/aljebra/common
import ../private/aljebra/vec

suite "Vec2":
  test "constructors and conversions":
    check vec2(1'f32, 2'f32) == Vec2(x: 1'f32, y: 2'f32)
    check ivec2(1'i32, 2'i32) == IVec2(x: 1'i32, y: 2'i32)
    check uvec2(1'u32, 2'u32) == UVec2(x: 1'u32, y: 2'u32)
    check vec2(3'f32) == vec2(3'f32, 3'f32)
    check ivec2(3'i32) == ivec2(3'i32, 3'i32)
    check uvec2(3'u32) == uvec2(3'u32, 3'u32)
    check vec2(ivec2(1'i32, 2'i32)) == vec2(1'f32, 2'f32)
    check ivec2(vec2(1'f32, 2'f32)) == ivec2(1'i32, 2'i32)
    check uvec2(ivec2(1'i32, 2'i32)) == uvec2(1'u32, 2'u32)
    check vec2([1'f32, 2'f32]) == vec2(1'f32, 2'f32)
    check vec2([0'f32, 1'f32, 2'f32], 1) == vec2(1'f32, 2'f32)

  test "component arithmetic":
    check vec2(1'f32, 2'f32) + vec2(3'f32, 4'f32) == vec2(4'f32, 6'f32)
    check ivec2(8'i32, 4'i32) / ivec2(2'i32, 2'i32) == ivec2(4'i32, 2'i32)
    check uvec2(8'u32, 4'u32) / uvec2(2'u32, 2'u32) == uvec2(4'u32, 2'u32)
    check vec2(3'f32, 4'f32) - 1 == vec2(2'f32, 3'f32)
    check 10 - vec2(3'f32, 4'f32) == vec2(7'f32, 6'f32)
    check vec2(3'f32, 4'f32) * 2 == vec2(6'f32, 8'f32)
    check vec2(8'f32, 4'f32) / 2 == vec2(4'f32, 2'f32)
    check 8 / ivec2(4'i32, 2'i32) == ivec2(2'i32, 4'i32)
    check 8 / uvec2(4'u32, 2'u32) == uvec2(2'u32, 4'u32)

  test "assignment arithmetic":
    var a = vec2(1'f32, 2'f32)
    a += vec2(3'f32, 4'f32)
    check a == vec2(4'f32, 6'f32)
    a -= 1
    check a == vec2(3'f32, 5'f32)
    a *= 2
    check a == vec2(6'f32, 10'f32)
    a /= 2
    check a == vec2(3'f32, 5'f32)

  test "math helpers":
    check lengthSq(vec2(3'f32, 4'f32)) == 25'f32
    check lengthSq(ivec2(3'i32, 4'i32)) == 25'i32
    check dot(vec2(1'f32, 2'f32), vec2(3'f32, 4'f32)) == 11'f32
    check dot(uvec2(1'u32, 2'u32), uvec2(3'u32, 4'u32)) == 11'u32
    check cross(vec2(1'f32, 2'f32), vec2(3'f32, 4'f32)) == -2'f32
    check floor(vec2(1.9'f32, -1.2'f32)) == vec2(1'f32, -2'f32)
    check round(vec2(1.4'f32, 1.6'f32)) == vec2(1'f32, 2'f32)
    check ceil(vec2(1.2'f32, -1.8'f32)) == vec2(2'f32, -1'f32)
    check floor(ivec2(1'i32, -2'i32)) == ivec2(1'i32, -2'i32)
    check round(uvec2(1'u32, 2'u32)) == uvec2(1'u32, 2'u32)
    check ceil(ivec2(1'i32, -2'i32)) == ivec2(1'i32, -2'i32)
    check clamp(vec2(5'f32, -1'f32), vec2(0'f32), vec2(3'f32)) == vec2(3'f32, 0'f32)
    check min(vec2(1'f32, 4'f32), vec2(2'f32, 3'f32)) == vec2(1'f32, 3'f32)
    check max(ivec2(1'i32, 4'i32), ivec2(2'i32, 3'i32)) == ivec2(2'i32, 4'i32)
    check sign(vec2(-2'f32, 3'f32)) == vec2(-1'f32, 1'f32)
    check sign(ivec2(-2'i32, 3'i32)) == ivec2(-1'i32, 1'i32)
    check quantize(vec2(2.7'f32, -2.7'f32), 1'f32) == vec2(2'f32, -2'f32)
    check quantize(ivec2(3'i32, -3'i32), 2'f32) == ivec2(2'i32, -2'i32)
    check almostEquals(vec2(1'f32, 1'f32), vec2(1'f32 + 0.000001'f32, 1'f32))

  test "indexing":
    var a = vec2(1'f32, 2'f32)
    check a[0] == 1'f32
    check a[1] == 2'f32
    a[0] = 3'f32
    a[1] = 4'f32
    check a == vec2(3'f32, 4'f32)
