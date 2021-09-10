const source* = """#version 300 es
precision mediump float;

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec2 in_uv;
layout(location = 3) in vec3 in_tangent;
layout(location = 4) in vec3 in_binormal;
layout(location = 5) in mat4 in_model_matrix;
layout(location = 9) in mat4 in_material_matrix;

/*
struct PointLight {    
    vec4 position;
    vec3 color;

    float constant;
    float linear;
    float quadratic;  
};  

struct DirectLight {
    vec3 direction;
    vec3 color;
};
*/  

struct Fog
{
    int enabled;
    vec4 color;
    float density;
    float gradient;
};

#define MAX_POINT_LIGHTS $MAX_POINT_LIGHTS$  
#define MAX_DIRECT_LIGHTS $MAX_DIRECT_LIGHTS$
#define MAX_INSTANCE $MAX_INSTANCE$

uniform Fog u_fog;
uniform vec3 u_ambient_color;
uniform mat4 u_view_matrix;
uniform mat4 u_projection_matrix;
uniform vec3 u_camera_position;
uniform mat4 u_depth_mvp;

const mat4 BIAS_MATRIX = mat4(0.5, 0.0, 0.0, 0.0,
                              0.0, 0.5, 0.0, 0.0,
                              0.0, 0.0, 0.5, 0.0,
                              0.5, 0.5, 0.5, 1.0);

// Model
out vec2 v_uv;
out vec3 v_normal;
out vec4 v_fragment_position;
out vec3 v_light_color;
out float v_visibilty;
out vec4 v_fog_color;
out vec4 v_shadow_position;
// Material
out vec4 v_diffuse_color;
out float v_opacity;
out vec3 v_specular_color;
out float v_shininess;
out float v_has_texture;
out float v_has_normal;

void main() {
    v_diffuse_color = vec4(in_material_matrix[0].xyz, 1.0);
    v_opacity = in_material_matrix[0].w;
    v_specular_color = in_material_matrix[1].xyz;
    v_shininess = in_material_matrix[1].w;
    v_has_texture = in_material_matrix[2].x;
    v_has_normal = in_material_matrix[2].y;

    vec4 position = vec4(in_position, 1.0);

    mat4 u_model_matrix = in_model_matrix;
    vec4 u_frame_offset = vec4(1, 1, 0, 0);
    
    mat4 u_normal_matrix = transpose(inverse(u_model_matrix));

    v_fragment_position = u_model_matrix * position;
    v_uv = (in_uv * u_frame_offset.xy) + u_frame_offset.zw;
    v_normal = mat3(u_normal_matrix) * in_normal;

    v_light_color = u_ambient_color;

    vec4 position_relative_to_view = u_view_matrix * v_fragment_position;
    if(u_fog.enabled > 0) {
        float distance = length(position_relative_to_view);
        float fog_factor = exp(-pow(distance * u_fog.density, u_fog.gradient));
        v_visibilty = clamp(fog_factor, 0.0, 1.0);
        v_fog_color = u_fog.color;
    } else {
        v_visibilty = -1.0;
    }

    v_shadow_position = u_depth_mvp * vec4(in_position, 1.0);

    gl_Position = u_projection_matrix * position_relative_to_view;
}
"""
