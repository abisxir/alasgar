$SHADER_PROFILE$
precision mediump float;
precision mediump sampler2DShadow;

out vec4 out_color;

#define MAX_SPOTPOINT_LIGHTS $MAX_SPOTPOINT_LIGHTS$
#define MAX_POINT_LIGHTS $MAX_POINT_LIGHTS$
#define MAX_DIRECT_LIGHTS $MAX_DIRECT_LIGHTS$

#define PI                  3.14159265359
#define HALF_PI             1.570796327
#define ONE_OVER_PI         0.3183098861837697
#define SHADOW_BIAS         0.00001
#define MEDIUMP_FLT_MAX     65504.0
#define saturate_mediump(x) min(x, MEDIUMP_FLT_MAX)
#define saturate(x)         clamp(x, 0.0, 1.0)
#define atan2(x, y)         atan(y, x)
#define sq(x)               x * x

#define DIFFUSE_LAMBERT             0
#define DIFFUSE_BURLEY              1

// Specular BRDF
// Normal distribution functions
#define SPECULAR_D_GGX              0

// Anisotropic NDFs
#define SPECULAR_D_GGX_ANISOTROPIC  0

// Cloth NDFs
#define SPECULAR_D_CHARLIE          0

// Visibility functions
#define SPECULAR_V_SMITH_GGX        0
#define SPECULAR_V_SMITH_GGX_FAST   1
#define SPECULAR_V_GGX_ANISOTROPIC  2
#define SPECULAR_V_KELEMEN          3
#define SPECULAR_V_NEUBELT          4

// Fresnel functions
#define SPECULAR_F_SCHLICK          0

#define BRDF_DIFFUSE                DIFFUSE_BURLEY

uniform struct Camera {
    highp vec3 position;
    highp mat4 view;
    highp mat4 projection;
    highp float exposure;
} camera;

uniform struct Frame {
    highp vec3 resolution;
    highp float time;
    highp float time_delta;
    highp float frame;
    highp vec4 mouse;
    highp vec4 date;
} frame;

uniform struct Environment {
    highp vec3 ambient_color;
    highp int fog_enabled;
    highp float fog_density;
    highp float fog_gradient;
    highp vec4 fog_color;
    highp int direct_lights_count;
    highp int spotpoint_lights_count;
    highp int point_lights_count;
    highp int shadow_enabled;
    highp vec3 shadow_position;
    highp mat4 shadow_mvp;
} env;

uniform struct PointLight {
    vec3 position;
    vec3 color;
    vec3 attenuation;
    float intensity;
} point_lights[MAX_POINT_LIGHTS];

uniform struct SpotLight {
    vec3 position;
    vec3 direction;
    vec3 color;
    float inner_limit;
    float outer_limit;
} spotpoint_lights[MAX_SPOTPOINT_LIGHTS];

uniform struct DirectLight {
    vec3 direction;
    float intensity;
} direct_lights[MAX_DIRECT_LIGHTS];

layout(binding = 0) uniform sampler2D u_depth_map;
layout(binding = 1) uniform sampler2D u_albedo_map;
layout(binding = 2) uniform sampler2D u_normal_map;
layout(binding = 3) uniform sampler2D u_metallic_map;
layout(binding = 4) uniform sampler2D u_roughness_map;
layout(binding = 5) uniform sampler2D u_ao_map;

in struct Surface {
    vec4 position;
    vec4 projected_position;
    vec4 shadow_light_position;
    vec3 direction_to_view;
    float visibilty;
    vec3 normal;
    vec2 uv;
} surface;

in struct Material {
    vec4 base_color;
    vec4 emissive_color;
    
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

float pow5(float x) {
    float x2 = x * x;
    return x2 * x2 * x;
}

float d_ggx(float roughness, float NoH, const vec3 n, const vec3 h) {
    vec3 NxH = cross(n, h);
    float a = NoH * roughness;
    float k = roughness / (dot(NxH, NxH) + a * a);
    float d = k * k * (1.0 / PI);
    return saturate_mediump(d);
}

float d_ggx_anisotropic(float at, float ab, float ToH, float BoH, float NoH) {
    // Burley 2012, "Physically-Based Shading at Disney"

    // The values at and ab are perceptualRoughness^2, a2 is therefore perceptualRoughness^4
    // The dot product below computes perceptualRoughness^8. We cannot fit in fp16 without clamping
    // the roughness to too high values so we perform the dot product and the division in fp32
    float a2 = at * ab;
    highp vec3 d = vec3(ab * ToH, at * BoH, a2 * NoH);
    highp float d2 = dot(d, d);
    float b2 = a2 / d2;
    return a2 * b2 * b2 * (1.0 / PI);
}

float d_charlie(float roughness, float NoH) {
    // Estevez and Kulla 2017, "Production Friendly Microfacet Sheen BRDF"
    float invAlpha  = 1.0 / roughness;
    float cos2h = NoH * NoH;
    float sin2h = max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
    return (2.0 + invAlpha) * pow(sin2h, invAlpha * 0.5) / (2.0 * PI);
}

float v_smith_ggx_correlated(float roughness, float NoV, float NoL) {
    // Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
    float a2 = roughness * roughness;
    // TODO: lambdaV can be pre-computed for all the lights, it should be moved out of this function
    float lambdaV = NoL * sqrt((NoV - a2 * NoV) * NoV + a2);
    float lambdaL = NoV * sqrt((NoL - a2 * NoL) * NoL + a2);
    float v = 0.5 / (lambdaV + lambdaL);
    // a2=0 => v = 1 / 4*NoL*NoV   => min=1/4, max=+inf
    // a2=1 => v = 1 / 2*(NoL+NoV) => min=1/4, max=+inf
    // clamp to the maximum value representable in mediump
    return saturate_mediump(v);
}

float v_smith_ggx_correlated_fast(float roughness, float NoV, float NoL) {
    // Hammon 2017, "PBR Diffuse Lighting for GGX+Smith Microsurfaces"
    float v = 0.5 / mix(2.0 * NoL * NoV, NoL + NoV, roughness);
    return saturate_mediump(v);
}

float v_smith_ggx_correlated_anisotropic(float at, float ab, float ToV, float BoV,
        float ToL, float BoL, float NoV, float NoL) {
    // Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
    // TODO: lambdaV can be pre-computed for all the lights, it should be moved out of this function
    float lambdaV = NoL * length(vec3(at * ToV, ab * BoV, NoV));
    float lambdaL = NoV * length(vec3(at * ToL, ab * BoL, NoL));
    float v = 0.5 / (lambdaV + lambdaL);
    return saturate_mediump(v);
}

float v_kelemen(float LoH) {
    // Kelemen 2001, "A Microfacet Based Coupled Specular-Matte BRDF Model with Importance Sampling"
    return saturate_mediump(0.25 / (LoH * LoH));
}

float v_neubelt(float NoV, float NoL) {
    // Neubelt and Pettineo 2013, "Crafting a Next-gen Material Pipeline for The Order: 1886"
    return saturate_mediump(1.0 / (4.0 * (NoL + NoV - NoL * NoV)));
}

vec3 f_schlick(vec3 f0, float f90, float VoH) {
    // Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
    return f0 + (f90 - f0) * pow5(1.0 - VoH);
}

vec3 f_schlick(vec3 f0, float VoH) {
    float f = pow5(1.0 - VoH);
    return f + f0 * (1.0 - f);
}

float f_schlick(float f0, float f90, float VoH) {
    return f0 + (f90 - f0) * pow5(1.0 - VoH);
}

float fd_lambert() {
    return 1.0 / PI;
}

float fd_burley(float roughness, float NoV, float NoL, float LoH) {
    // Burley 2012, "Physically-Based Shading at Disney"
    float f90 = 0.5 + 2.0 * roughness * LoH * LoH;
    float lightScatter = f_schlick(1.0, f90, NoL);
    float viewScatter  = f_schlick(1.0, f90, NoV);
    return lightScatter * viewScatter * (1.0 / PI);
}

// Energy conserving wrap diffuse term, does *not* include the divide by pi
float fd_wrap(float NoL, float w) {
    return saturate((NoL + w) / sq(1.0 + w));
}

float diffuse(float roughness, float NoV, float NoL, float LoH) {
#if BRDF_DIFFUSE == DIFFUSE_LAMBERT
    return fd_lambert();
#elif BRDF_DIFFUSE == DIFFUSE_BURLEY
    return fd_burley(roughness, NoV, NoL, LoH);
#endif
}

vec3 brdf(vec3 l, vec3 v, vec3 n, float NoV, vec3 albedo, vec3 f0, float roughness) {
    vec3 h = normalize(v + l);

    float NoL = clamp(dot(n, l), 0.0, 1.0);
    float NoH = clamp(dot(n, h), 0.0, 1.0);
    float LoH = clamp(dot(l, h), 0.0, 1.0);
    float linear_roughness = roughness * roughness;

    float D = d_ggx(linear_roughness, NoH, n, h);
    vec3  F = f_schlick(f0, LoH);
    float V = v_smith_ggx_correlated_fast(NoV, NoL, roughness);

    // specular BRDF
    vec3 Fr = (D * V) * F;

    // diffuse BRDF
    vec3 Fd = albedo * diffuse(roughness, NoV, NoL, LoH);

    // apply lighting...
    return NoL * (Fd + Fr); //* pixel.energyCompensation;
}

float varianc_shadow_map(vec4 light_space_position)
{
    float distance = light_space_position.z;
    vec2 moments = texture(u_depth_map, light_space_position.xy).rg;

    // Surface is fully lit. as the current fragment is before the light occluder
    if (distance <= moments.x)
        return 1.0;

    // The fragment is either in shadow or penumbra. We now use chebyshev's upperBound to check
    // How likely this pixel is to be lit (p_max)
    float variance = moments.y - (moments.x*moments.x);
    //variance = max(variance, 0.000002);
    variance = max(variance, 0.00002);

    float d = distance - moments.x;
    float p_max = variance / (variance + d*d);

    return p_max * 0.5;
}

float simple_shadow_map(vec4 light_space_position, vec3 surface_normal) {
    vec3 shadow_direction = normalize(env.shadow_position - surface.position.xyz);
    float bias = max(SHADOW_BIAS * (1.0 - dot(surface_normal, shadow_direction)), SHADOW_BIAS);

    float shadow_depth = texture(u_depth_map, light_space_position.xy).r;
    float model_depth = light_space_position.z;
    if (model_depth - bias >= shadow_depth) {
        return 0.5;
    }
    return 1.0;
}

vec3 get_normal() {
    if(material.has_normal_map > 0.0) {
        vec3 pos_dx = dFdx(surface.position.xyz);
        vec3 pos_dy = dFdy(surface.position.xyz);
        vec2 tex_dx = dFdx(surface.uv);
        vec2 tex_dy = dFdy(surface.uv);
        
        vec3 t = normalize(pos_dx * tex_dy.t - pos_dy * tex_dx.t);
        vec3 b = normalize(-pos_dx * tex_dy.s + pos_dy * tex_dx.s);

        mat3 tbn = mat3(t, b, normalize(surface.normal));
        vec3 normal = texture(u_normal_map, surface.uv).rgb * 2.0 - 1.0;

        return (vec4(normal, 0.0) * camera.view).xyz;
    } else {
        return normalize(surface.normal);
    }
}

$MAIN_FUNCTION$

void main() {
    out_color = texture(u_metallic_map, surface.uv);
    return;

    vec4 base_color = material.base_color;
    if(material.has_albedo_map > 0.0) {
        base_color *= texture(u_albedo_map, surface.uv);
    }

    float alpha = base_color.a;
    if(alpha < 0.01) {
        discard;
    }

    vec3 N = get_normal();
    vec3 V = normalize(camera.position - surface.position.xyz);
    float NoV = abs(dot(N, V)) + 1e-5;

    float metallic = material.metallic;
    if(material.has_metallic_map > 0.0) {
        metallic *= texture(u_metallic_map, surface.uv).r;
    }

    float roughness = material.roughness;
    if(material.has_roughness_map > 0.0) {
        roughness *= texture(u_roughness_map, surface.uv).r;
    }

    float ao = material.ao;
    if(material.has_ao_map > 0.0) {
        ao *= texture(u_ao_map, surface.uv).r;
    }

    vec3 albedo = (1.0 - metallic) * base_color.rgb;
    vec3 f0 = 0.16 * material.reflectance * material.reflectance * (1.0 - metallic) + albedo * metallic;

    int point_light_count = min(MAX_POINT_LIGHTS, env.point_lights_count);
    vec3 lights_effect = env.ambient_color;
    for(int i = 0; i < point_light_count; i++) {
        vec3 light_direction = point_lights[i].position - surface.position.xyz;
        float distance = length(light_direction);
        float illuminance = point_lights[i].intensity / dot(point_lights[i].attenuation, vec3(1.0, distance, distance * distance));
        
        vec3 L = normalize(light_direction);
        //vec3 effect = calculate_lighting_analytical(N, L, V, albedo, f0, roughness);
        vec3 effect = brdf(L, V, N, NoV, albedo, f0, roughness);

        lights_effect += effect * illuminance * point_lights[i].color;
    }

    // Mixes with ambient occlusion map
    lights_effect = mix(lights_effect, lights_effect * ao, 1.0);
    // Adds emissive color
    lights_effect += material.emissive_color.rgb;

    out_color = vec4(lights_effect, alpha);
}

/*
void main() 
{
    float v_shininess = 0.0;
    out_color = material.base_color;
    if(material.has_albedo_map > 0.0) {
        out_color = texture(u_albedo_map, surface.uv) * material.base_color;
    }
    if(out_color.a < 0.01) {
        discard;
    } else {
        vec3 light_color = env.ambient_color;
        vec3 view_direction = normalize(camera.position - surface.position.xyz);
        vec3 surface_normal;

        if(material.has_normal_map > 0.0) {
            vec3 Q1 = dFdx(surface.position.xyz);
            vec3 Q2 = dFdy(surface.position.xyz);
            vec2 st1 = dFdx(surface.uv);
            vec2 st2 = dFdy(surface.uv);
            
            vec3 T = normalize(Q1*st2.t - Q2*st1.t);
            vec3 B = normalize(-Q1*st2.s + Q2*st1.s);
                
            // the transpose of texture-to-eye space matrix
            mat3 TBN = mat3(T, B, surface.normal);            
            vec3 t_normal = texture(u_normal_map, surface.uv).rgb * 2.0 - 1.0;
            surface_normal = normalize(TBN * t_normal);
        } else {
            surface_normal = normalize(surface.normal);
        }
        
        int point_light_count = min(MAX_POINT_LIGHTS, env.point_lights_count);
        for(int i = 0; i < point_light_count; i++) {
            vec3 light_direction = point_lights[i].position - surface.position.xyz;
            vec3 normalized_light_direction = normalize(light_direction);
            vec3 half_vector = normalize(normalized_light_direction + surface.direction_to_view);

            float lambert_factor = dot(surface_normal, normalized_light_direction);
            float specular_factor = 0.0;
            if (lambert_factor > 0.0) {
                float distance = length(light_direction);
                specular_factor = pow(dot(surface_normal, half_vector), v_shininess);
                float attenuation = point_lights[i].intensity / (point_lights[i].constant + point_lights[i].linear * distance + point_lights[i].quadratic * (distance * distance));
                light_color += attenuation * specular_factor * material.emissive_color.rgb + attenuation * lambert_factor * point_lights[i].color;
            }
        }

        int spotpoint_light_count = min(MAX_SPOTPOINT_LIGHTS, env.spotpoint_lights_count);
        for(int i = 0; i < spotpoint_light_count; i++) {
            vec3 normalized_light_direction = normalize(spotpoint_lights[i].position - surface.position.xyz);
            vec3 normalized_surface_to_view_direction = normalize(surface.direction_to_view);
            vec3 half_vector = normalize(normalized_light_direction + normalized_surface_to_view_direction);

            float dot_from_direction = dot(normalized_light_direction, -spotpoint_lights[i].direction);
            float limit_range = spotpoint_lights[i].inner_limit - spotpoint_lights[i].outer_limit;
            //float in_light = clamp((dot_from_direction - spotpoint_lights[i].outer_limit) / limit_range, 0.0, 1.0);
            float in_light = smoothstep(spotpoint_lights[i].outer_limit, spotpoint_lights[i].inner_limit, dot_from_direction);

            // Calculates diffuse factor
            float diffuse_factor = in_light * dot(surface_normal, normalized_light_direction);
            light_color += spotpoint_lights[i].color * diffuse_factor;

            // Calculates specular factor
            float specular_factor = in_light * pow(dot(surface_normal, half_vector), v_shininess);
            light_color += spotpoint_lights[i].color * specular_factor;
        }


        int direct_light_count = min(MAX_DIRECT_LIGHTS, env.direct_lights_count);
        for(int i = 0; i < direct_light_count; i++) {
            float direct_light_factor = dot(surface_normal, -direct_lights[i].direction);
            light_color += direct_lights[i].color * direct_light_factor;
        }


        if(env.shadow_enabled > 0) {
            vec4 light_space_position = surface.shadow_light_position / surface.shadow_light_position.w;
            light_space_position = light_space_position * 0.5 + 0.5;

            bool out_of_shadow = surface.shadow_light_position.w <= 0.0 
                || (light_space_position.x < 0.0 || light_space_position.y < 0.0) 
                || (light_space_position.x >= 1.0 || light_space_position.y >= 1.0);

            if(!out_of_shadow) {
                //light_color = light_color * chebyshevUpperBound(light_space_position.xy, light_space_position.z);
                //light_color = light_color * texture(u_depth_map, light_space_position.xyz);
                
                //light_color *= simple_shadow_map(light_space_position, surface_normal);
                light_color *= varianc_shadow_map(light_space_position);
            }
        }

        out_color *= vec4(light_color, 1.0);

        if(surface.visibilty > 0.0) {
            out_color = mix(env.fog_color, out_color, surface.visibilty);
        }

        out_color = vec4(material.metallic, material.roughness, material.reflectance, material.ao);
        //out_color = vec4(1.0, 0.0, 0.0, 1.0);

        $MAIN_FUNCTION_CALL$
    }
}
*/