$SHADER_PROFILE$
precision highp float;

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec2 in_uv;
layout(location = 3) in vec3 in_tangent;
layout(location = 4) in vec3 in_binormal;
layout(location = 5) in mat4 in_model_matrix;
layout(location = 9) in mat4 in_material_matrix;


// Camera
uniform vec3 u_view_position;
uniform mat4 u_view_matrix;
uniform mat4 u_projection_matrix;

// Fog
uniform int u_fog_enabled;
uniform vec4 u_fog_color;
uniform float u_fog_density;
uniform float u_fog_gradient;

// Shadow
uniform mat4 u_shadow_mvp;

// Model
out vec2 v_uv;
out vec3 v_normal;
out vec4 v_fragment_position;
out vec3 v_surface_to_view;
out float v_visibilty;
out vec4 v_fog_color;
out vec4 v_shadow_light_position;

// Material
out vec4 v_diffuse_color;
out float v_opacity;
out vec3 v_specular_color;
out float v_shininess;
out float v_has_texture;
out float v_has_normal;

void main() {
    v_diffuse_color = in_material_matrix[0].xyzw;
    v_opacity = in_material_matrix[0].w;
    v_specular_color = in_material_matrix[1].xyz;
    v_shininess = in_material_matrix[1].w;
    v_has_texture = in_material_matrix[2].x;
    v_has_normal = in_material_matrix[2].y;
    vec2 frame_size = in_material_matrix[2].zw;
    vec2 frame_offset = in_material_matrix[3].xy;
    vec2 texture_ratio = in_material_matrix[3].zw;

    vec4 position = vec4(in_position, 1.0);
    mat4 normal_matrix = transpose(inverse(in_model_matrix));

    v_fragment_position = in_model_matrix * position;
    v_normal = mat3(normal_matrix) * in_normal;
    v_shadow_light_position = u_shadow_mvp * v_fragment_position;
    v_surface_to_view = normalize(u_view_position - v_fragment_position.xyz);

    if(frame_size.x > 0.0) {
        v_uv = (in_uv * frame_size) + frame_offset;
    } else {
        v_uv = in_uv;
    }

    vec4 position_related_to_view = u_view_matrix * v_fragment_position;
    if(u_fog_enabled > 0) {
        float distance = length(position_related_to_view);
        float fog_factor = exp(-pow(distance * u_fog_density, u_fog_gradient));
        v_visibilty = clamp(fog_factor, 0.0, 1.0);
        v_fog_color = u_fog_color;
    } else {
        v_visibilty = -1.0;
    }
    
    gl_Position = u_projection_matrix * position_related_to_view;
}
