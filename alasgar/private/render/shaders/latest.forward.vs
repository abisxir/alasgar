$SHADER_PROFILE$
precision highp float;

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec2 in_uv;
layout(location = 3) in vec3 in_tangent;
layout(location = 4) in vec3 in_binormal;
layout(location = 5) in mat4 in_model;
layout(location = 9) in uvec4 in_material;
layout(location = 10) in vec4 in_sprite;


// Camera
uniform struct Camera {
    vec3 position;
    mat4 view;
    mat4 projection;
    float exposure;
} camera;

uniform struct Environment {
    vec3 ambient_color;
    int fog_enabled;
    float fog_density;
    float fog_gradient;
    vec4 fog_color;
    int direct_lights_count;
    int spotpoint_lights_count;
    int point_lights_count;
    int shadow_enabled;
    vec3 shadow_position;
    mat4 shadow_mvp;
} env;

uniform struct Frame {
    vec3 resolution;
    float time;
    float time_delta;
    float frame;
    vec4 mouse;
    vec4 date;
} frame;

out struct Surface {
    vec4 position;
    vec4 projected_position;
    vec4 shadow_light_position;
    vec3 direction_to_view;
    float visibilty;
    vec3 normal;
    vec2 uv;
} surface;

out struct Material {
    vec4 base_color;
    vec4 emmisive_color;
    float metallic;
    float roughness;
    float reflectance;
    float ao;
    float has_albedo_map;
    float has_normal_map;
    float has_metallic_map;
    float has_roughness_map;
    float has_ao_map;
} material;

$MAIN_FUNCTION$

#define ALBEDO_MAP_FLAG     1u
#define NORMAL_MAP_FLAG     2u
#define METALLIC_MAP_FLAG   4u
#define ROUGHNESS_MAP_FLAG  8u
#define AO_MAP_FLAG         16u

float has_flag(uint value, uint flag) {
    uint r = value & flag;
    return r == flag ? 1.0 : 0.0;
}

void main() {
    material.base_color = unpackUnorm4x8(in_material.x);
    material.emmisive_color = unpackUnorm4x8(in_material.y);
    
    vec4 unpacked_factors = unpackUnorm4x8(in_material.z);
    material.metallic = unpacked_factors.x;
    material.roughness = unpacked_factors.y;
    material.reflectance = unpacked_factors.z;
    material.ao = unpacked_factors.w;

    material.has_albedo_map = has_flag(in_material.w, ALBEDO_MAP_FLAG);
    material.has_normal_map = has_flag(in_material.w, NORMAL_MAP_FLAG);
    material.has_metallic_map = has_flag(in_material.w, METALLIC_MAP_FLAG);
    material.has_roughness_map = has_flag(in_material.w, ROUGHNESS_MAP_FLAG);
    material.has_ao_map = has_flag(in_material.w, AO_MAP_FLAG);

    vec2 frame_size = in_sprite.xy; 
    vec2 frame_offset = in_sprite.zw;

    vec4 position = vec4(in_position, 1.0);
    mat4 normal_matrix = transpose(inverse(in_model));

    surface.position = in_model * position;
    surface.normal = mat3(normal_matrix) * in_normal;
    surface.shadow_light_position = env.shadow_mvp * surface.position;
    surface.direction_to_view = normalize(camera.position - surface.position.xyz);

    if(frame_size.x > 0.0) {
        surface.uv = (in_uv * frame_size) + frame_offset;
    } else {
        surface.uv = in_uv;
    }

    vec4 position_related_to_view = camera.view * surface.position;
    if(env.fog_enabled > 0) {
        float distance = length(position_related_to_view);
        float fog_factor = exp(-pow(distance * env.fog_density, env.fog_gradient));
        surface.visibilty = clamp(fog_factor, 0.0, 1.0);
    } else {
        surface.visibilty = -1.0;
    }
  
    surface.projected_position = camera.projection * position_related_to_view;

    $MAIN_FUNCTION_CALL$
    gl_Position = surface.projected_position;
}
