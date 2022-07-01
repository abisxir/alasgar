$SHADER_PROFILE$
precision mediump float;
precision mediump sampler2DShadow;

out vec4 out_color;

#define MAX_SPOTPOINT_LIGHTS $MAX_SPOTPOINT_LIGHTS$
#define MAX_POINT_LIGHTS $MAX_POINT_LIGHTS$
#define MAX_DIRECT_LIGHTS $MAX_DIRECT_LIGHTS$

#define PI                  3.141592653
#define HALF_PI             1.570796327
#define ONE_OVER_PI         0.318309886
#define HALF_ONE_OVER_PI    0.159154943
#define LN2                 0.6931472
#define SHADOW_BIAS         0.00001
#define MEDIUMP_FLT_MAX     65504.0
#define saturate_mediump(x) min(x, MEDIUMP_FLT_MAX)
#define saturate(x)         clamp(x, 0.0, 1.0)
#define atan2(x, y)         atan(y, x)
#define sq(x)               x * x

#define DIFFUSE_LAMBERT             0
#define DIFFUSE_BURLEY              1
#define BRDF_DIFFUSE                DIFFUSE_LAMBERT

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


float pow5(float x) {
    float x2 = x * x;
    return x2 * x2 * x;
}

/*
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

float diffuse(float roughness, float NoV, float NoL, float LoH) {
#if BRDF_DIFFUSE == DIFFUSE_LAMBERT
    return fd_lambert();
#elif BRDF_DIFFUSE == DIFFUSE_BURLEY
    return fd_burley(roughness, NoV, NoL, LoH);
#endif
}
*/

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

vec3 specularReflection(vec3 specularEnvR0, vec3 specularEnvR90, float VdH) {
    return specularEnvR0 + (specularEnvR90 - specularEnvR0) * pow(clamp(1.0 - VdH, 0.0, 1.0), 5.0);
}

float geometricOcclusion(float NdL, float NdV, float roughness) {
    float r = roughness;
    float attenuationL = 2.0 * NdL / (NdL + sqrt(r * r + (1.0 - r * r) * (NdL * NdL)));
    float attenuationV = 2.0 * NdV / (NdV + sqrt(r * r + (1.0 - r * r) * (NdV * NdV)));
    return attenuationL * attenuationV;
}

float microfacetDistribution(float roughness, float NdH) {
    float roughnessSq = roughness * roughness;
    float f = (NdH * roughnessSq - NdH) * NdH + 1.0;
    return roughnessSq / (PI * f * f);
}

vec2 cartesianToPolar(vec3 n) {
    vec2 uv;
    uv.x = atan(n.z, n.x) * HALF_ONE_OVER_PI + 0.5;
    uv.y = asin(n.y) * ONE_OVER_PI + 0.5;
    return uv;
}

$MAIN_FUNCTION$

void main() {
    vec4 base_color = material.base_color;
    if(material.has_albedo_map > 0.0) {
        base_color *= texture(u_albedo_map, surface.uv);
    }

    vec3 albedo = base_color.rgb;
    float alpha = base_color.a;
    if(alpha < 0.01) {
        discard;
    }

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

    metallic = clamp(metallic, 0.04, 1.0);
    roughness = clamp(metallic, 0.04, 1.0);
    vec3 baseColor = albedo;
    vec3 f0 = vec3(0.04);
    vec3 diffuseColor = baseColor * (vec3(1.0) - f0) * (1.0 - metallic);
    vec3 specularColor = mix(f0, baseColor, metallic);
    vec3 specularEnvR0 = specularColor;
    vec3 specularEnvR90 = vec3(clamp(max(max(specularColor.r, specularColor.g), specularColor.b) * 25.0, 0.0, 1.0));    

    vec3 uLightDirection = vec3(0.0) - vec3(5.0);
    vec3 uLightColor = vec3(1.0);
    float uOcclusion = 1.0;

    vec3 N = get_normal();
    vec3 V = normalize(camera.position - surface.position.xyz);
    vec3 L = normalize(point_lights[0].position - surface.position.xyz);
    vec3 H = normalize(L + V);
    vec3 reflection = normalize(reflect(-V, N));

    float NdL = clamp(dot(N, L), 0.001, 1.0);
    float NdV = clamp(abs(dot(N, V)), 0.001, 1.0);
    float NdH = clamp(dot(N, H), 0.0, 1.0);
    float LdH = clamp(dot(L, H), 0.0, 1.0);
    float VdH = clamp(dot(V, H), 0.0, 1.0);    

    vec3 F = specularReflection(specularEnvR0, specularEnvR90, VdH);
    float G = geometricOcclusion(NdL, NdV, roughness);
    float D = microfacetDistribution(roughness, NdH);
    vec3 diffuseContrib = (1.0 - F) * (diffuseColor / PI);
    vec3 specContrib = F * G * D / (4.0 * NdL * NdV);
    
    // Shading based off lights
    vec3 color = NdL * uLightColor * (diffuseContrib + specContrib);
    // If the material has alpha texture
    //alpha *= texture(tOpacity, vUv).g;
    // Add lights spec to alpha for reflections on transparent surfaces (glass)
    alpha = max(alpha, max(max(specContrib.r, specContrib.g), specContrib.b));

    /*
    // Calculate IBL lighting
    vec3 diffuseIBL;
    vec3 specularIBL;
    getIBLContribution(diffuseIBL, specularIBL, NdV, roughness, N, reflection, diffuseColor, specularColor);
    // Add IBL on top of color
    color += diffuseIBL + specularIBL;
    // Add IBL spec to alpha for reflections on transparent surfaces (glass)
    alpha = max(alpha, max(max(specularIBL.r, specularIBL.g), specularIBL.b));
    */

    // Multiply occlusion
    color = mix(color, color * ao, uOcclusion);

    // Adds emissive color
    color += material.emissive_color.rgb;

    // Convert to sRGB to display
    out_color.rgb = color;//linearToSRGB(color);
    
    // Apply uAlpha uniform at the end to overwrite any specular additions on transparent surfaces
    out_color.a = alpha;// * uAlpha;    

    /*
    int point_light_count = min(MAX_POINT_LIGHTS, env.point_lights_count);
    vec3 lights_effect = env.ambient_color;
    for(int i = 0; i < point_light_count; i++) {
        vec3 light_direction = surface.position.xyz - point_lights[i].position;
        float distance = length(light_direction);
        vec3 to_light = normalize(light_direction);
        float illuminance = point_lights[i].intensity / dot(point_lights[i].attenuation, vec3(1.0, distance, distance * distance));
        float angle = dot(surface_normal, light_direction) * 0.15;
        //vec3 effect = calculate_lighting_analytical(surface_normal, to_light, normalize(surface.direction_to_view), albedo, f0, roughness);
        //vec3 effect = brdf(to_light, normalize(surface.direction_to_view), surface_normal, albedo, f0, roughness);

        lights_effect += point_lights[i].color * angle;
    }

    // Mixes with ambient occlusion map
    lights_effect = mix(lights_effect, lights_effect * ao, 1.0);
    // Adds emissive color
    lights_effect += material.emissive_color.rgb;

    out_color.rgb *= lights_effect;
    */
}
