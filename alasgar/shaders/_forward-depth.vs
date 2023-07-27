$SHADER_PROFILE$
precision highp float;

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec4 in_uv;
layout(location = 3) in ivec4 in_bone;
layout(location = 4) in vec4 in_weight;
layout(location = 5) in mat4 in_model;
layout(location = 9) in uvec4 in_material;
layout(location = 10) in vec4 in_sprite;

uniform mat4 u_shadow_mvp;

out float v_depth;

void main() {
    vec4 fragment_position = in_model * vec4(in_position, 1.0);
    vec4 light_position = u_shadow_mvp * fragment_position;
    float nz = light_position.z / light_position.w;
    v_depth = 0.5 + (nz * 0.5);
    gl_Position = light_position;
}

