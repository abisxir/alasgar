#version 300 es
precision mediump float;
precision mediump sampler2DShadow;

struct PointLight {
    vec3 position;
    vec3 color;
    float constant;
    float linear;
    float quadratic;
    float intensity;
};

struct SpotLight {
    vec3 position;
    vec3 direction;
    vec3 color;
    float inner_limit;
    float outer_limit;      
};

struct DirectLight {
    vec3 direction;
    vec3 color;
};


#define MAX_SPOTPOINT_LIGHTS $MAX_SPOTPOINT_LIGHTS$
#define MAX_POINT_LIGHTS $MAX_POINT_LIGHTS$
#define MAX_DIRECT_LIGHTS $MAX_DIRECT_LIGHTS$

const float PI = 3.14159265359;
const float MIN_SHADOW_BIAS = 0.00001;
const float MAX_SHADOW_BIAS = 0.001;

uniform PointLight u_point_lights[MAX_POINT_LIGHTS];
uniform int u_point_lights_count;
uniform SpotLight u_spotpoint_lights[MAX_SPOTPOINT_LIGHTS];
uniform int u_spotpoint_lights_count;
uniform DirectLight u_direct_lights[MAX_DIRECT_LIGHTS];
uniform int u_direct_lights_count;
uniform sampler2D u_depth_texture;
//uniform sampler2DShadow u_depth_texture;
uniform sampler2D u_diffuse_texture;
uniform sampler2D u_normal_texture;
uniform vec3 u_ambient_color;
uniform vec3 u_camera_position;
uniform int u_shadow_enabled;
uniform vec3 u_shadow_position;

// Model
in vec2 v_uv;
in vec3 v_normal;
in vec4 v_fragment_position;
in vec4 v_position_related_to_view;
in vec3 v_surface_to_view;
in float v_visibilty;
in vec4 v_fog_color;

// Shadow
in vec4 v_shadow_light_position;
in mat4 v_shadow_matrix;

// Material
in vec4 v_diffuse_color;
in float v_opacity;
in vec3 v_specular_color;
in float v_shininess;
in float v_has_texture;
in float v_has_normal;


out vec4 out_diffuse;

float calculate_oren_nayar_diffuse_factor(
  vec3 light_direction,
  vec3 view_direction,
  vec3 surface_normal,
  float roughness,
  float albedo) {
  
  float LdotV = dot(light_direction, view_direction);
  float NdotL = dot(light_direction, surface_normal);
  float NdotV = dot(surface_normal, view_direction);

  float s = LdotV - NdotL * NdotV;
  float t = mix(1.0, max(NdotL, NdotV), step(0.0, s));

  float sigma2 = roughness * roughness;
  float A = 1.0 + sigma2 * (albedo / (sigma2 + 0.13) + 0.5 / (sigma2 + 0.33));
  float B = 0.45 * sigma2 / (sigma2 + 0.09);

  return albedo * max(0.0, NdotL) * (A + B * s / t) / PI;
}


/*
float map_simple_shadow() {
    vec3 shadow_direction = normalize(u_shadow_position - v_fragment_position.xyz);
    vec4 light_space_position = v_shadow_light_position / v_shadow_light_position.w;
    light_space_position = light_space_position * 0.5 + 0.5;
    float bias = max(MAX_SHADOW_BIAS * (1.0 - dot(surface_normal, shadow_direction)), MIN_SHADOW_BIAS);

    bool out_of_shadow = v_shadow_light_position.w <= 0.0 
        || (light_space_position.x < 0.0 || light_space_position.y < 0.0) 
        || (light_space_position.x >= 1.0 || light_space_position.y >= 1.0);


    if(!out_of_shadow) {
        float shadow_depth = texture(u_depth_texture, light_space_position.xy).r;
        float model_depth = light_space_position.z;
        if (model_depth < shadow_depth) {
            return shadow_depth;
        }
    }

    return -1.0;
}
*/


float shadow_simple(in sampler2DShadow shadow_map, in vec4 shadow_map_pos)
{
  // perform perspective divide
  vec3 shadow_map_uv = shadow_map_pos.xyz / shadow_map_pos.w;

  if (shadow_map_uv.z < 0.0 || shadow_map_uv.z > 1.0)
    return 0.0;

  // get closest depth value from light's perspective
  float closest_depth = texture(shadow_map, shadow_map_uv);

  // get depth of current fragment from light's perspective
  float current_depth = shadow_map_uv.z;

  // check whether current frag pos is in shadow
  float shadow = current_depth > closest_depth  ? 1.0 : 0.0;

  return shadow;
}


void main() 
{
    out_diffuse = v_diffuse_color;
    if(v_has_texture > 0.0) {
        out_diffuse = texture(u_diffuse_texture, v_uv) * v_diffuse_color;
    }
    if(out_diffuse.a < 0.01) {
        discard;
    } else {
        vec3 light_color = u_ambient_color;
        vec3 view_direction = normalize(u_camera_position - v_fragment_position.xyz);
        vec3 surface_normal = normalize(v_normal);
        
        int point_light_count = min(MAX_POINT_LIGHTS, u_point_lights_count);
        for(int i = 0; i < point_light_count; i++) {
            vec3 light_direction = u_point_lights[i].position - v_fragment_position.xyz;
            vec3 normalized_light_direction = normalize(light_direction);
            vec3 half_vector = normalize(normalized_light_direction + v_surface_to_view);

            float lambert_factor = dot(surface_normal, normalized_light_direction);
            float specular_factor = 0.0;
            if (lambert_factor > 0.0) {
                float distance = length(light_direction);
                specular_factor = pow(dot(surface_normal, half_vector), v_shininess);
                float attenuation = u_point_lights[i].intensity / (u_point_lights[i].constant + u_point_lights[i].linear * distance + u_point_lights[i].quadratic * (distance * distance));
                light_color += attenuation * specular_factor * v_specular_color + attenuation * lambert_factor * u_point_lights[i].color;
            }
        }

        int spotpoint_light_count = min(MAX_SPOTPOINT_LIGHTS, u_spotpoint_lights_count);
        for(int i = 0; i < spotpoint_light_count; i++) {
            vec3 normalized_light_direction = normalize(u_spotpoint_lights[i].position - v_fragment_position.xyz);
            vec3 normalized_surface_to_view_direction = normalize(v_surface_to_view);
            vec3 half_vector = normalize(normalized_light_direction + normalized_surface_to_view_direction);

            float dot_from_direction = dot(normalized_light_direction, -u_spotpoint_lights[i].direction);
            float limit_range = u_spotpoint_lights[i].inner_limit - u_spotpoint_lights[i].outer_limit;
            //float in_light = clamp((dot_from_direction - u_spotpoint_lights[i].outer_limit) / limit_range, 0.0, 1.0);
            float in_light = smoothstep(u_spotpoint_lights[i].outer_limit, u_spotpoint_lights[i].inner_limit, dot_from_direction);

            // Calculates diffuse factor
            float diffuse_factor = in_light * dot(surface_normal, normalized_light_direction);
            light_color += u_spotpoint_lights[i].color * diffuse_factor;

            // Calculates specular factor
            float specular_factor = in_light * pow(dot(surface_normal, half_vector), v_shininess);
            light_color += u_spotpoint_lights[i].color * specular_factor;
        }


        int direct_light_count = min(MAX_DIRECT_LIGHTS, u_direct_lights_count);
        for(int i = 0; i < direct_light_count; i++) {
            float direct_light_factor = dot(surface_normal, -u_direct_lights[i].direction);
            light_color += u_direct_lights[i].color * direct_light_factor;
        }


        if(u_shadow_enabled > 0) {
            vec3 shadow_direction = normalize(u_shadow_position - v_fragment_position.xyz);
            vec4 light_space_position = v_shadow_light_position / v_shadow_light_position.w;
            light_space_position = light_space_position * 0.5 + 0.5;
            float bias = max(MAX_SHADOW_BIAS * (1.0 - dot(surface_normal, shadow_direction)), MIN_SHADOW_BIAS);

            bool out_of_shadow = v_shadow_light_position.w <= 0.0 
                || (light_space_position.x < 0.0 || light_space_position.y < 0.0) 
                || (light_space_position.x >= 1.0 || light_space_position.y >= 1.0);

            if(!out_of_shadow) {
                //float shadow_factor = texture(u_depth_texture, v_shadow_light_position.xyz);
                //light_color *= shadow_factor;
                float shadow_depth = texture(u_depth_texture, light_space_position.xy).r;
                float model_depth = light_space_position.z - bias;
                if (model_depth < shadow_depth) {
                    light_color = light_color * shadow_depth;
                }
            }
        }

        out_diffuse *= vec4(light_color, 1.0);

        if(v_visibilty >= 0.0) {
            out_diffuse = mix(v_fog_color, out_diffuse, v_visibilty);
        }
    }
}
