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

layout(binding = 0) uniform sampler2D u_depth_map;
layout(binding = 1) uniform sampler2D u_albedo_map;
layout(binding = 2) uniform sampler2D u_normal_map;
layout(binding = 3) uniform sampler2D u_metallic_map;
layout(binding = 4) uniform sampler2D u_roughness_map;
layout(binding = 5) uniform sampler2D u_ao_map;
layout(binding = 6) uniform sampler2D u_env_lut_map;
layout(binding = 7) uniform sampler2D u_env_diffuse_map;
layout(binding = 8) uniform sampler2D u_env_specular_map;

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

float pow5(float x) {
    float x2 = x * x;
    return x2 * x2 * x;
}


float f_schlick(float f0, float f90, float VoH) {
    return f0 + (f90 - f0) * pow5(1.0 - VoH);
}

vec3 f_schlick(float cos_theta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cos_theta, 0.0, 1.0), 5.0);
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

float diffuse(float roughness, float NoV, float NoL, float LoH) {
#if BRDF_DIFFUSE == DIFFUSE_LAMBERT
    return fd_lambert();
#elif BRDF_DIFFUSE == DIFFUSE_BURLEY
    return fd_burley(roughness, NoV, NoL, LoH);
#endif
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

        return normalize((vec4(normal, 0.0) * camera.view).xyz);
    } else {
        return normalize(surface.normal);
    }
}

float DistributionGGX(vec3 N, vec3 H, float roughness)
{
    float a      = roughness * roughness;
    float a2     = a * a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;
	
    float num   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
	
    return num / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;
	
    return num / denom;
}

float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);
	
    return ggx1 * ggx2;
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

    vec3 F0 = mix(vec3(0.04), albedo, metallic);

    vec3 N = get_normal();
    vec3 V = normalize(camera.position - surface.position.xyz);
    float NoV = clamp(abs(dot(N, V)), 0.001, 1.0);

    int point_light_count = min(MAX_POINT_LIGHTS, env.point_lights_count);
    vec3 Lo = vec3(0.0);
    for(int i = 0; i < point_light_count; i++) {
        vec3 light_direction = point_lights[i].position - surface.position.xyz;
        vec3 L = normalize(light_direction);
        vec3 H = normalize(L + V);
        vec3 reflection = normalize(reflect(-V, N));

        float NoL = clamp(dot(N, L), 0.001, 1.0);
        float NoH = clamp(dot(N, H), 0.0, 1.0);
        float LoH = clamp(dot(L, H), 0.0, 1.0);
        float VoH = clamp(dot(V, H), 0.0, 1.0);    

        float distance = length(light_direction);
        float attenuation = 1.0 / (distance * distance);

        vec3 radiance  = point_lights[i].color * attenuation;

        vec3 F  = f_schlick(max(dot(H, V), 0.0), F0);
        float NDF = DistributionGGX(N, H, roughness);       
        float G   = GeometrySmith(N, V, L, roughness);          

        vec3 numerator    = NDF * G * F;
        float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0)  + 0.0001;
        vec3 specular     = numerator / denominator;           

        vec3 kS = F;
        vec3 kD = vec3(1.0) - kS;
        
        kD *= 1.0 - metallic;
        Lo += (kD * albedo / PI + specular) * radiance * NoL;        
    }

    vec3 ambient = vec3(0.03) * albedo * ao;
    vec3 color = ambient + Lo;
	
    color = color / (color + vec3(1.0));
    color = pow(color, vec3(1.0/2.2));    

    out_color = vec4(color, alpha);
}
