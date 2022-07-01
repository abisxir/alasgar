$SHADER_PROFILE$
precision highp float;
precision highp int;
precision highp sampler2DShadow;

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
    vec4 shadow_light_position;
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

/**
 * Standard Lambertian diffuse lighting.
 */
vec3 fd_lambert(in vec3 albedo)
{                              
    return (albedo * ONE_OVER_PI);
}


/**
 * GGX/Schlick-Beckmann microfacet geometric attenuation.
 */
float calculate_attenuation(in float product, in float k)
{
    float d = max(product, 0.0);
 	return (d / ((d * (1.0 - k)) + k));
}

/**
 * GGX/Trowbridge-Reitz NDF
 */
float calculate_ndf(in vec3 surface_normal, in vec3  half_vector, in float roughness)
{
    float a2 = (roughness * roughness);
    float half_angle = dot(surface_normal, half_vector);

    return (a2 / (PI * pow((pow(half_angle, 2.0) * (a2 - 1.0) + 1.0), 2.0)));
}

/**
 * GGX/Schlick-Beckmann attenuation for analytical light sources.
 */
float calculate_attenuation_analytical(float NoL, float NoV, in float roughness)
{
    float k = pow((roughness + 1.0), 2.0) * 0.125;

    // G(l) and G(v)
    float light_attenuation = calculate_attenuation(NoL, k);
    float view_attenuation = calculate_attenuation(NoV, k);

    // Smith
    return (light_attenuation * view_attenuation);
}

/**
 * Calculates the Fresnel reflectivity.
 */
vec3 calculate_fresnel(in vec3 surface_normal, in vec3 to_view, in vec3 fresnel0)
{
	float d = max(dot(surface_normal, to_view), 0.0);
    float p = ((-5.55473 * d) - 6.98316) * d;

    // Fresnel-Schlick approximation
    //return fresnel0 + ((1.0 - fresnel0) * pow5(1.0 - d));
    // modified by Spherical Gaussian approximation to replace the power, more efficient
    return fresnel0 + ((1.0 - fresnel0) * pow(2.0, p));
}

/**
 * Cook-Torrance BRDF for analytical light sources.
 */
vec3 calculate_specular_analytical(
    in vec3 surface_normal,       // Surface normal
    in vec3 to_light,             // Normalized vector pointing to light source
    in vec3 to_view,              // Normalized vector point to the view/camera
    in float NoL,
    in float NoV,
    in vec3 fresnel0,             // Fresnel incidence value
    inout vec3 sfresnel,          // Final fresnel value used a kS
    in float roughness)           // Roughness parameter (microfacet contribution)
{
    vec3 half_vector = normalize(to_light + to_view);

    float ndf = calculate_ndf(surface_normal, half_vector, roughness);
    float geo_attenuation = calculate_attenuation_analytical(NoL, NoV, roughness);

    sfresnel = calculate_fresnel(surface_normal, to_view, fresnel0);

    vec3  numerator = (sfresnel * ndf * geo_attenuation); // FDG
    float denominator = 4.0 * NoL * NoV;

    return (numerator / denominator);
}

/**
 * Calculates the total light contribution for the analytical light source.
 */
vec3 calculate_lighting_analytical(in vec3 N, in vec3 L, in vec3 V, in float NoV, in vec3 albedo, in vec3 f0, in float roughness)
{
    float NoL = dot(N, L);
    vec3 ks = vec3(0.0);
    vec3 kd = (1.0 - ks);
    vec3 diffuse = fd_lambert(albedo);
    vec3 specular = calculate_specular_analytical(
        N, 
        L, 
        V, 
        NoL,
        NoV,
        f0, 
        ks, 
        roughness
    );

    return NoL * ((kd * diffuse) + specular);
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

$MAIN_FUNCTION$

void main() {
    out_color = material.base_color;
    if(material.has_albedo_map > 0.0) {
        out_color *= texture(u_albedo_map, surface.uv);
    }

    float alpha = out_color.a;
    if(alpha < 0.01) {
        discard;
    }

    vec3 N = get_normal();
    vec3 V = normalize(camera.position - surface.position.xyz);
    float NoV = abs(dot(N, V)) + 1e-5;
    /*
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
    */

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

    vec3 albedo = (1.0 - metallic) * out_color.rgb;
    vec3 f0 = 0.16 * material.reflectance * material.reflectance * (1.0 - metallic) + albedo * metallic;

    int point_light_count = min(MAX_POINT_LIGHTS, env.point_lights_count);
    vec3 lights_effect = env.ambient_color;
    for(int i = 0; i < point_light_count; i++) {
        vec3 light_direction = point_lights[i].position - surface.position.xyz;
        float distance = length(light_direction);
        vec3 L = normalize(light_direction);
        float illuminance = point_lights[i].intensity / dot(point_lights[i].attenuation, vec3(1.0, distance, distance * distance));
        
        vec3 effect = calculate_lighting_analytical(N, L, V, NoV, albedo, f0, roughness);
        //vec3 effect = brdf(L, V, N, albedo, f0, roughness);

        lights_effect += effect * illuminance * point_lights[i].color;
    }

    float indirectIntesity = 0.4;
    vec3 indirectDiffuse = Irradiance_SphericalHarmonics(N) * fd_lambert(albedo);
    vec2 dfg = PrefilteredDFG_Karis(roughness, NoV);
    vec3 specularColor = f0 * dfg.x + dfg.y;
    vec3 indirectSpecular = vec3(0.2);
    vec3 ibl = albedo * indirectDiffuse + indirectSpecular * specularColor;

    // Mixes with ambient occlusion map
    lights_effect = mix(lights_effect, lights_effect * ao, 1.0);
    // Adds emissive color
    lights_effect += material.emissive_color.rgb;

    out_color = vec4(lights_effect, alpha);
    out_color.rgb += ibl * iblIntesity;
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