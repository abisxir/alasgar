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

uniform struct Camera {
    highp vec3 position;
    highp mat4 view;
    highp mat4 projection;
    highp float exposure;
    highp float gamma;
} camera;

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

uniform struct Frame {
    highp vec3 resolution;
    highp float time;
    highp float time_delta;
    highp float frame;
    highp vec4 mouse;
    highp vec4 date;
} frame;

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
layout(binding = 6) uniform sampler2D u_emissive_map;
layout(binding = 7) uniform samplerCube u_environment_map;

in struct Surface {
    vec4 position;
    vec4 shadow_light_position;
    float visibilty;
    vec3 normal;
    vec2 uv;
} surface;

in struct Material {
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

float pow5(float x) {
    float x2 = x * x;
    return x2 * x2 * x;
}

float calculate_oren_nayar_diffuse_factor(
  vec3 light_direction,
  vec3 view_direction,
  vec3 surface_normal,
  float roughness,
  float albedo) {
  
  float LdotV = dot(light_direction, view_direction);
  float NdotL = dot(surface_normal, light_direction);
  float NdotV = dot(surface_normal, view_direction);

  float s = LdotV - NdotL * NdotV;
  float t = mix(1.0, max(NdotL, NdotV), step(0.0, s));

  float sigma2 = roughness * roughness;
  float A = 1.0 + sigma2 * (albedo / (sigma2 + 0.13) + 0.5 / (sigma2 + 0.33));
  float B = 0.45 * sigma2 / (sigma2 + 0.09);

  return albedo * max(0.0, NdotL) * (A + B * s / t) / PI;
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

vec3 get_normal(vec3 V) {
    vec3 N = normalize(surface.normal);
    if(material.has_normal_map > 0.0) {
        vec3 dp1 = dFdx(surface.position.xyz);
        vec3 dp2 = dFdy(surface.position.xyz);
        vec2 duv1 = dFdx(surface.uv);
        vec2 duv2 = dFdy(surface.uv);

        vec3 dp2perp = cross( dp2, N );
        vec3 dp1perp = cross( N, dp1 );
        vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
        vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;

        /* construct a scale-invariant frame */
        float invmax = inversesqrt(max(dot(T,T), dot(B,B)));
        mat3 TBN = mat3(T * invmax, B * invmax, N);
        vec3 map = normalize(texture(u_normal_map, surface.uv).rgb * 2.007874 - 1.007874);
        return normalize(TBN * map);
    } 
    return N;
}

float D_GGX(float linearRoughness, float NoH, const vec3 h) {
    // Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"
    float oneMinusNoHSquared = 1.0 - NoH * NoH;
    float a = NoH * linearRoughness;
    float k = linearRoughness / (oneMinusNoHSquared + a * a);
    float d = k * k * (1.0 / PI);
    return d;
}

float V_SmithGGXCorrelated(float a2, float NoV, float NoL, float ggx_factor_const) {
    // Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
    float GGXV = NoL * ggx_factor_const;
    float GGXL = NoV * sqrt((NoL - a2 * NoL) * NoL + a2);
    return 0.5 / (GGXV + GGXL);
}

vec3 F_Schlick(const vec3 f0, float VoH) {
    // Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
    return f0 + (vec3(1.0) - f0) * pow5(1.0 - VoH);
}

float F_Schlick(float f0, float f90, float VoH) {
    return f0 + (f90 - f0) * pow5(1.0 - VoH);
}

float Fd_Burley(float linearRoughness, float NoV, float NoL, float LoH) {
    // Burley 2012, "Physically-Based Shading at Disney"
    float f90 = 0.5 + 2.0 * linearRoughness * LoH * LoH;
    float lightScatter = F_Schlick(1.0, f90, NoL);
    float viewScatter  = F_Schlick(1.0, f90, NoV);
    return lightScatter * viewScatter * (1.0 / PI);
}

float Fd_Lambert() {
    return 1.0 / PI;
}

//------------------------------------------------------------------------------
// Indirect lighting
//------------------------------------------------------------------------------

vec3 Irradiance_SphericalHarmonics(const vec3 n) {
    // Irradiance from "Ditch River" IBL (http://www.hdrlabs.com/sibl/archive.html)
    return max(
          vec3( 0.754554516862612,  0.748542953903366,  0.790921515418539)
        + vec3(-0.083856548007422,  0.092533500963210,  0.322764661032516) * (n.y)
        + vec3( 0.308152705331738,  0.366796330467391,  0.466698181299906) * (n.z)
        + vec3(-0.188884931542396, -0.277402551592231, -0.377844212327557) * (n.x)
        , 0.0);
}

vec2 PrefilteredDFG_Karis(float roughness, float NoV) {
    // Karis 2014, "Physically Based Material on Mobile"
    const vec4 c0 = vec4(-1.0, -0.0275, -0.572,  0.022);
    const vec4 c1 = vec4( 1.0,  0.0425,  1.040, -0.040);

    vec4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;

    return vec2(-1.04, 1.04) * a004 + r.zw;
}

vec3 tonemap_aces(const vec3 x) {
    // Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

vec3 calculate_specular_indirect(vec3 V, vec3 N, float roughness) {
    float mip_count = 9.0;
    float lod = roughness * mip_count;
    vec3 reflection = -normalize(reflect(V, N));
    vec3 specular = textureLod(u_environment_map, reflection, lod).rgb;
    return specular;
}

$MAIN_FUNCTION$

void main() {
    if(material.opacity < 0.01) {
        discard;
    } 

    vec3 V = normalize(camera.position - surface.position.xyz);
    out_color = vec4(material.base_color, material.opacity);
    //out_color.rgb = get_normal(V);
    //return;
    if(material.has_albedo_map > 0.0) {
        out_color = out_color * texture(u_albedo_map, surface.uv);
    }

    float metallic = material.metallic;
    if(material.has_metallic_map > 0.0) {
        metallic *= texture(u_metallic_map, surface.uv).g;
    }

    float roughness = material.roughness;
    if(material.has_roughness_map > 0.0) {
        roughness *= texture(u_roughness_map, surface.uv).b;
    }

    float ao = material.ao;
    if(material.has_ao_map > 0.0) {
        ao *= texture(u_ao_map, surface.uv).r;
    }

    vec3 albedo = (1.0 - metallic) * out_color.rgb;
    vec3 f0 = 0.04 * (1.0 - metallic) + out_color.rgb * metallic;
    //vec3 f0 = 0.16 * material.reflectance * material.reflectance * (1.0 - metallic) + out_color.rgb * metallic;

    float linearRoughness = roughness * roughness;
    float a2 = linearRoughness * linearRoughness;
    vec3 N = get_normal(V);
    float NoV = abs(dot(N, V)) + 1e-5;
    float ggx_factor_const = sqrt((NoV - a2 * NoV) * NoV + a2);
    float indirectIntensity = 0.64;

    int point_light_count = min(MAX_POINT_LIGHTS, env.point_lights_count);
    vec3 lights_effect = env.ambient_color;
    for(int i = 0; i < point_light_count; i++) {
        vec3 direction = point_lights[i].position - surface.position.xyz;
        float distance = length(direction);
        vec3 L = normalize(direction);
        vec3 R = normalize(reflect(-direction, N));
        vec3 H = normalize(V + L);
        float NoV = abs(dot(N, V)) + 1e-5;
        float NoL = saturate(dot(N, L));
        float NoH = saturate(dot(N, H));
        float LoH = saturate(dot(L, H));
        float attenuation = point_lights[i].intensity / dot(point_lights[i].attenuation, vec3(1.0, distance, distance * distance));
        
        // specular BRDF
        float D = D_GGX(linearRoughness, NoH, H);
        float V = V_SmithGGXCorrelated(a2, NoV, NoL, ggx_factor_const);
        vec3  F = F_Schlick(f0, LoH);
        vec3 Fr = (D * V) * F;

        // diffuse BRDF
        vec3 Fd = albedo * Fd_Lambert(); //Fd_Burley(linearRoughness, NoV, NoL, LoH);

        lights_effect += (Fd + Fr) * (point_lights[i].intensity * attenuation * NoL) * point_lights[i].color;
    }

    // Calculates indirect lights
    vec3 indirectDiffuse = Irradiance_SphericalHarmonics(N) * Fd_Lambert();
    vec2 dfg = PrefilteredDFG_Karis(roughness, NoV);
    vec3 specularColor = f0 * material.specular_color * dfg.x + dfg.y;
    vec3 indirectSpecular = calculate_specular_indirect(V, N, roughness);
    vec3 ibl = albedo * indirectDiffuse + indirectSpecular * specularColor;

    // Adds IBL
    lights_effect += ibl * indirectIntensity;

    // Mixes with ambient occlusion map
    lights_effect = mix(lights_effect, lights_effect * ao, 1.0);

    // Adds emissive color
    if(material.has_emissive_map > 0.0) {
        lights_effect += texture(u_emissive_map, surface.uv).rgb;
    } else {
        lights_effect += material.emissive_color;
    }

    out_color = vec4(tonemap_aces(lights_effect), out_color.a);
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