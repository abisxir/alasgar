$SHADER_PROFILE$
precision highp float;
precision highp int;

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec4 in_tangent;
layout(location = 3) in vec4 in_uv;
layout(location = 4) in mat4 in_model;
layout(location = 8) in uvec4 in_material;
layout(location = 9) in vec4 in_sprite;


// Camera
uniform struct Camera {
    vec3 position;
    mat4 view;
    mat4 projection;
    float exposure;
    float gamma;
} camera;

uniform struct Environment {
    vec3 ambient_color;
    int fog_enabled;
    float fog_density;
    float fog_gradient;
    vec4 fog_color;
    int lights_count;
    float mip_count;
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
    vec4 shadow_light_position;
    float visibilty;
    vec3 normal;
    vec2 uv;
} surface;

out struct Material {
    vec3 base_color;
    vec3 specular_color;
    vec3 emissive_color;
    float opacity;

    float metallic;
    float roughness;
    float reflectance;
    float ao;

    float has_albedo_map;
    float has_normal_map;
    float has_metallic_map;
    float has_roughness_map;
    float has_ao_map;
    float has_emissive_map;

    float albedo_map_uv_channel;
    float normal_map_uv_channel;
    float metallic_map_uv_channel;
    float roughness_map_uv_channel;
    float ao_map_uv_channel;
    float emissive_map_uv_channel;
} material;

$MAIN_FUNCTION$

#define ALBEDO_MAP_FLAG     1u
#define NORMAL_MAP_FLAG     2u
#define METALLIC_MAP_FLAG   4u
#define ROUGHNESS_MAP_FLAG  8u
#define AO_MAP_FLAG         16u
#define EMISSIVE_MAP_FLAG   32u

float has_flag(uint value, uint flag) {
    uint r = value & flag;
    return r == flag ? 1.0 : 0.0;
}

void extract_material_data() {
    vec4 base_color = unpackUnorm4x8(in_material.x);
    material.base_color = base_color.rgb;
    material.opacity = base_color.a;
    vec4 specular_color = unpackUnorm4x8(in_material.y);
    material.specular_color = specular_color.rgb;
    vec4 emissive_color = unpackUnorm4x8(in_material.z);
    uint flags = uint(round(emissive_color.a * 63.0));
    uint uv_channels = uint(round(specular_color.a * 63.0));
    material.emissive_color = emissive_color.rgb;
    
    vec4 unpacked_factors = unpackUnorm4x8(in_material.w);
    material.metallic = unpacked_factors.x;
    material.roughness = unpacked_factors.y;
    material.reflectance = unpacked_factors.z;
    material.ao = unpacked_factors.w;

    material.has_albedo_map = has_flag(flags, ALBEDO_MAP_FLAG);
    material.albedo_map_uv_channel = has_flag(uv_channels, ALBEDO_MAP_FLAG);
    material.has_normal_map = has_flag(flags, NORMAL_MAP_FLAG);
    material.normal_map_uv_channel = has_flag(uv_channels, NORMAL_MAP_FLAG);
    material.has_metallic_map = has_flag(flags, METALLIC_MAP_FLAG);
    material.metallic_map_uv_channel = has_flag(uv_channels, METALLIC_MAP_FLAG);
    material.has_roughness_map = has_flag(flags, ROUGHNESS_MAP_FLAG);
    material.roughness_map_uv_channel = has_flag(uv_channels, ROUGHNESS_MAP_FLAG);
    material.has_ao_map = has_flag(flags, AO_MAP_FLAG);
    material.ao_map_uv_channel = has_flag(uv_channels, AO_MAP_FLAG);
    material.has_emissive_map = has_flag(flags, EMISSIVE_MAP_FLAG);
    material.emissive_map_uv_channel = has_flag(uv_channels, EMISSIVE_MAP_FLAG);
}

void main() {
    extract_material_data();

    vec2 frame_size = in_sprite.xy; 
    vec2 frame_offset = in_sprite.zw;

    vec4 position = vec4(in_position, 1.0);
    mat4 normal_matrix = transpose(inverse(in_model));

    surface.position = in_model * position;
    //surface.normal = (normal_matrix * vec4(in_normal, 0.0)).xyz;
    surface.normal = (in_model * vec4(in_normal, 0.0)).xyz;
    surface.shadow_light_position = env.shadow_mvp * surface.position;

    if(frame_size.x > 0.0) {
        surface.uv = (in_uv.xy * frame_size) + frame_offset;
    } else {
        surface.uv = in_uv.xy;
    }

    vec4 position_related_to_view = camera.view * surface.position;
    if(env.fog_enabled > 0) {
        float distance = length(position_related_to_view);
        float fog_factor = exp(-pow(distance * env.fog_density, env.fog_gradient));
        surface.visibilty = clamp(fog_factor, 0.0, 1.0);
    } else {
        surface.visibilty = -1.0;
    }
  
    $MAIN_FUNCTION_CALL$
    gl_Position = camera.projection * position_related_to_view;;
}
