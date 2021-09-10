#version 300 es
precision mediump float;

uniform sampler2D frame_buffer_texture;

in vec2 v_uv;

out vec4 out_fragment_color;

void main() 
{
    out_fragment_color = texture(frame_buffer_texture, v_uv);
}
