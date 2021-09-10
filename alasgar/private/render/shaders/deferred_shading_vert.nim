const source* = """#version 300 es
precision mediump float;

layout(location = 0) in vec2 in_position;
layout(location = 1) in vec2 in_uv;

out vec2 v_uv;

void main() {
    v_uv = in_uv;
    gl_Position = vec4(in_position, 0, 1.0);
}
"""
