$SHADER_PROFILE$
precision mediump float;
precision mediump sampler2DShadow;

out vec4 out_color;

#define MAX_LIGHTS $MAX_LIGHTS$

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
    highp int lights_count;
    highp float mip_count;
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

#define LIGHT_TYPE_DIRECTIONAL  0
#define LIGHT_TYPE_POINT        1
#define LIGHT_TYPE_SPOT         2

layout(binding = 0) uniform sampler2D u_depth_map;
layout(binding = 1) uniform sampler2D u_albedo_map;
layout(binding = 2) uniform sampler2D u_normal_map;
layout(binding = 3) uniform sampler2D u_metallic_map;
layout(binding = 4) uniform sampler2D u_roughness_map;
layout(binding = 5) uniform sampler2D u_ao_map;
layout(binding = 6) uniform sampler2D u_emissive_map;
layout(binding = 7) uniform samplerCube u_environment_map;
layout(binding = 8) uniform samplerCube u_ggx_map;
layout(binding = 9) uniform sampler2D u_lut_map;

uniform struct Light {
    vec3 color;
    float intensity;
    vec3 position;
    vec3 direction;
    float range;
    float inner_cone_cos;
    float outer_cone_cos;
    int type;
    sampler2D depth_map;
} lights[MAX_LIGHTS + 1];

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

#define PI                  3.14159265359
#define HALF_PI             1.570796327
#define ONE_OVER_PI         0.3183098861837697
#define SHADOW_BIAS         0.00001
#define MEDIUMP_FLT_MAX     65504.0
#define saturate_mediump(x) min(x, MEDIUMP_FLT_MAX)
#define saturate(x)         clamp(x, 0.00001, 1.0)
#define atan2(x, y)         atan(y, x)
#define sq(x)               x * x
#define GAMMA               2.2
#define INV_GAMMA           1.0 / GAMMA

// TODO provide normal scale in material
const float NORMAL_SCALE = 0.9;
const float INDIRECT_INTENSITY = 0.6;
const float OCCLUSION_STRENGTH = 1.0;
const float SPECULAR_WEIGHT = 0.6;

float pow5(float x) {
    float x2 = x * x;
    return x2 * x2 * x;
}

float get_range_attenuation(float range, float distance)
{
    if (range <= 0.0)
    {
        // negative range means unlimited
        return 1.0 / pow(distance, 2.0);
    }
    return max(min(1.0 - pow(distance / range, 4.0), 1.0), 0.0) / pow(distance, 2.0);
}

float get_spot_attenuation(vec3 point_to_light, vec3 direction, float outer_cone_cos, float inner_cone_cos)
{
    float actual_cos = dot(normalize(direction), normalize(-point_to_light));
    if (actual_cos > outer_cone_cos)
    {
        if (actual_cos < inner_cone_cos)
        {
            return smoothstep(outer_cone_cos, inner_cone_cos, actual_cos);
        }
        return 1.0;
    }
    return 0.0;
}

vec3 get_light_intensity(Light light, vec3 point_to_light, float distance)
{
    float range_attenuation = 1.0;
    float spot_attenuation = 1.0;

    if (light.type != LIGHT_TYPE_DIRECTIONAL)
    {
        range_attenuation = get_range_attenuation(light.range, distance);
    }
    if (light.type == LIGHT_TYPE_SPOT)
    {
        spot_attenuation = get_spot_attenuation(point_to_light, light.direction, light.outer_cone_cos, light.inner_cone_cos);
    }

    return range_attenuation * spot_attenuation * light.intensity * light.color;
}

vec3 get_ibl_radiance_ggx(vec3 N, vec3 V, float NoV, float roughness, vec3 f0, float SPECULAR_WEIGHT)
{
    float lod = roughness * (env.mip_count - 1.0);
    vec3 reflection = normalize(reflect(-V, N));

    vec2 brdf_sample_point = clamp(vec2(NoV, roughness), vec2(0.0, 0.0), vec2(1.0, 1.0));
    vec2 f_ab = texture(u_lut_map, brdf_sample_point).rg;
    // TODO: provide env.intensity
    vec4 specular_sample = textureLod(u_ggx_map, reflection, lod);// * env.intensity;

    vec3 specular_light = specular_sample.rgb;

    // see https://bruop.github.io/ibl/#single_scattering_results at Single Scattering Results
    // Roughness dependent fresnel, from Fdez-Aguera
    vec3 Fr = max(vec3(1.0 - roughness), f0) - f0;
    vec3 k_S = f0 + Fr * pow5(1.0 - NoV);
    vec3 FssEss = k_S * f_ab.x + f_ab.y;

    return SPECULAR_WEIGHT * specular_light * FssEss;
}

vec3 calculate_irradiance_spherical_harmonics(const vec3 n) {
    // Irradiance from "Ditch River" IBL (http://www.hdrlabs.com/sibl/archive.html)
    return max(
          vec3( 0.754554516862612,  0.748542953903366,  0.790921515418539)
        + vec3(-0.083856548007422,  0.092533500963210,  0.322764661032516) * (n.y)
        + vec3( 0.308152705331738,  0.366796330467391,  0.466698181299906) * (n.z)
        + vec3(-0.188884931542396, -0.277402551592231, -0.377844212327557) * (n.x)
        , 0.0);
}

vec3 get_ibl_radiance_lambertian(vec3 n, vec3 v, float NoV, float roughness, vec3 diffuse_color, vec3 f0, float SPECULAR_WEIGHT)
{
    vec2 brdf_sample_point = clamp(vec2(NoV, roughness), vec2(0.0, 0.0), vec2(1.0, 1.0));
    vec2 f_ab = texture(u_lut_map, brdf_sample_point).rg;

    //vec3 irradiance = get_diffuse_light(n);
    vec3 irradiance = calculate_irradiance_spherical_harmonics(n);

    // see https://bruop.github.io/ibl/#single_scattering_results at Single Scattering Results
    // Roughness dependent fresnel, from Fdez-Aguera

    vec3 Fr = max(vec3(1.0 - roughness), f0) - f0;
    vec3 k_S = f0 + Fr * pow(1.0 - NoV, 5.0);
    vec3 FssEss = SPECULAR_WEIGHT * k_S * f_ab.x + f_ab.y; // <--- GGX / specular light contribution (scale it down if the specularWeight is low)

    // Multiple scattering, from Fdez-Aguera
    float Ems = (1.0 - (f_ab.x + f_ab.y));
    vec3 F_avg = SPECULAR_WEIGHT * (f0 + (1.0 - f0) / 21.0);
    vec3 FmsEms = Ems * FssEss * F_avg / (1.0 - F_avg * Ems);
    vec3 k_D = diffuse_color * (1.0 - FssEss + FmsEms); // we use +FmsEms as indicated by the formula in the blog post (might be a typo in the implementation)

    return (FmsEms + k_D) * irradiance;
}

vec3 get_normal() {
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
        vec3 map = texture(u_normal_map, surface.uv).rgb * 2.007874 - 1.007874;
        return normalize(TBN * map);
    } 
    return N;
}

float D_GGX(float alpha_roughness, float NoH) {
    // Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"
    float oneMinusNoHSquared = 1.0 - NoH * NoH;
    float a = NoH * alpha_roughness;
    float k = alpha_roughness / (oneMinusNoHSquared + a * a);
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

float Fd_Burley(float alpha_roughness, float NoV, float NoL, float LoH) {
    // Burley 2012, "Physically-Based Shading at Disney"
    float f90 = 0.5 + 2.0 * alpha_roughness * LoH * LoH;
    float light_scatter = F_Schlick(1.0, f90, NoL);
    float view_scatter  = F_Schlick(1.0, f90, NoV);
    return light_scatter * view_scatter * (1.0 / PI);
}

float Fd_Lambert() {
    return ONE_OVER_PI;
}

vec2 get_prefiltered_dfg_karis(float roughness, float NoV) {
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

vec3 linearTosRGB(vec3 color)
{
    return pow(color, vec3(INV_GAMMA));
}

vec3 sRGBToLinear(vec3 srgbIn)
{
    return vec3(pow(srgbIn.xyz, vec3(GAMMA)));
}

vec3 calculate_specular_indirect(vec3 V, vec3 N, float roughness) {
    float lod = roughness * env.mip_count;
    vec3 reflection = -normalize(reflect(V, N));
    vec3 specular = textureLod(u_ggx_map, reflection, lod).rgb;
    return specular;
}

vec3 calculare_lambertian_brdf(vec3 f0, vec3 diffuseColor, float specularWeight, float VoH)
{
    vec3 F = F_Schlick(f0, VoH);
    // see https://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/
    return (1.0 - specularWeight * F) * (diffuseColor / PI);
}

vec3 calculate_specular_brdf(vec3 f0, float alpha_roughness, float a2, float specularWeight, float VoH, float NoL, float NoV, float NoH, float ggx_factor_const)
{
    vec3 F = F_Schlick(f0, VoH);
    float Vis = V_SmithGGXCorrelated(NoL, NoV, a2, ggx_factor_const);
    float D = D_GGX(alpha_roughness, NoH);

    return specularWeight * F * Vis * D;
}

vec3 get_normal(vec3 v)
{
    vec2 UV = surface.uv;
    vec3 v_Position = surface.position.xyz;
    vec3 v_Normal = normalize(surface.normal);
    vec3 uv_dx = dFdx(vec3(UV, 0.0));
    vec3 uv_dy = dFdy(vec3(UV, 0.0));

    vec3 t_ = (uv_dy.t * dFdx(v_Position) - uv_dx.t * dFdy(v_Position)) /
        (uv_dx.s * uv_dy.t - uv_dy.s * uv_dx.t);

    vec3 n, t, b, ng;
    ng = normalize(v_Normal);
    t = normalize(t_ - ng * dot(ng, t_));
    b = cross(ng, t);

    // For a back-facing surface, the tangential basis vectors are negated.
    if (gl_FrontFacing == false)
    {
        t *= -1.0;
        b *= -1.0;
        ng *= -1.0;
    }

    // Compute pertubed normals:
    if(material.has_normal_map > 0.0) {
        n = texture(u_normal_map, UV).rgb * 2.0 - vec3(1.0);
        n *= vec3(NORMAL_SCALE, NORMAL_SCALE, 1.0);
        n = mat3(t, b, ng) * normalize(n);
    } else {
        n = ng;
    }
    return n;
}

void light_pbr(vec3 N, vec3 V, vec3 base_color, float metallic, float roughness, float ao, out vec3 f_specular, out vec3 f_diffuse) {
    vec3 f0 = 0.04 * (1.0 - metallic) + base_color.rgb * metallic;
    vec3 albedo = mix(base_color.rgb * (vec3(1.0) - f0),  vec3(0), metallic);
    // TODO: use reflectance
    //float reflectance = max(max(f0.r, f0.g), f0.b);

    float alpha_roughness = roughness * roughness;
    float a2 = alpha_roughness * alpha_roughness;
    float NoV = abs(dot(N, V)) + 1e-5;
    float ggx_factor_const = sqrt((NoV - a2 * NoV) * NoV + a2);

    // Calculates indirect lights
    f_diffuse += INDIRECT_INTENSITY * calculate_irradiance_spherical_harmonics(N) * Fd_Lambert() * albedo;
    vec2 dfg = get_prefiltered_dfg_karis(roughness, NoV);
    vec3 specular_color = f0 * material.specular_color * dfg.x + dfg.y;
    f_specular += INDIRECT_INTENSITY * specular_color * calculate_specular_indirect(V, N, roughness);

    // Adds occlusion
    f_diffuse = mix(f_diffuse, f_diffuse * ao, OCCLUSION_STRENGTH);
    f_specular = mix(f_specular, f_specular * ao, OCCLUSION_STRENGTH);

    int lights_count = min(MAX_LIGHTS, env.lights_count);
    for(int i = 0; i < lights_count; i++) {
        vec3 point_to_light = lights[i].position - surface.position.xyz;
        float distance = length(point_to_light);
        vec3 L = normalize(point_to_light);
        vec3 R = normalize(reflect(-L, N));
        vec3 H = normalize(V + L);
        float NoV = abs(dot(N, V)) + 1e-5;
        float NoL = saturate(dot(N, L));
        float NoH = saturate(dot(N, H));
        float LoH = saturate(dot(L, H));
        float VoH = saturate(dot(V, H));
        //float attenuation = lights[i].intensity / dot(lights[i].attenuation, vec3(1.0, distance, distance * distance));
        vec3 intensity = get_light_intensity(lights[i], point_to_light, distance);
        
        f_diffuse += intensity * NoL * calculare_lambertian_brdf(f0, albedo, SPECULAR_WEIGHT, VoH);
		f_specular += intensity * NoL * calculate_specular_brdf(f0, alpha_roughness, a2, SPECULAR_WEIGHT, VoH, NoL, NoV, NoH, ggx_factor_const);
    }
}

$MAIN_FUNCTION$

void main() {
    if(material.opacity < 0.01) {
        discard;
    } 

    vec4 base_color = vec4(material.base_color, material.opacity);
    if(material.has_albedo_map > 0.0) {
        base_color = base_color * texture(u_albedo_map, surface.uv);
    }

	if(base_color.a < 0.01) {
		discard;
	}

    float metallic = material.metallic;
    if(material.has_metallic_map > 0.0) {
        metallic *= texture(u_metallic_map, surface.uv).b;
    }

    float roughness = material.roughness;
    if(material.has_roughness_map > 0.0) {
        roughness *= texture(u_roughness_map, surface.uv).g;
    }

    float ao = material.ao;
    if(material.has_ao_map > 0.0) {
        ao *= texture(u_ao_map, surface.uv).r;
    }

    vec3 f_specular = vec3(0.0);
    vec3 f_diffuse = env.ambient_color;

    vec3 V = normalize(camera.position - surface.position.xyz);
    vec3 N = get_normal();

    if(roughness > 0.0 || metallic > 0.0) {
        light_pbr(N, V, sRGBToLinear(base_color.rgb), metallic, roughness, ao, f_specular, f_diffuse);
    } else {
        
    }

    // Adds emissive color
    vec3 f_emissive = material.emissive_color;
    if(material.has_emissive_map > 0.0) {
        f_emissive = texture(u_emissive_map, surface.uv).rgb;
    } 

    out_color.rgb =  linearTosRGB(tonemap_aces(f_emissive + f_diffuse + f_specular));
    out_color.a = base_color.a;
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