$SHADER_PROFILE$
precision mediump float;
precision mediump sampler2DShadow;

#define MAX_LIGHTS $MAX_LIGHTS$

layout(binding = 0) uniform sampler2D u_albedo_map;
layout(binding = 1) uniform sampler2D u_normal_map;
layout(binding = 2) uniform sampler2D u_metallic_map;
layout(binding = 3) uniform sampler2D u_roughness_map;
layout(binding = 4) uniform sampler2D u_ao_map;
layout(binding = 5) uniform sampler2D u_emissive_map;
layout(binding = 6) uniform samplerCube u_ggx_map;
layout(binding = 7) uniform sampler2D u_depth_maps_0;
layout(binding = 8) uniform sampler2D u_depth_maps_1;
layout(binding = 9) uniform sampler2D u_depth_maps_2;
layout(binding = 10) uniform sampler2D u_depth_maps_3;
layout(binding = 11) uniform samplerCube u_cube_depth_maps_0;
layout(binding = 12) uniform samplerCube u_cube_depth_maps_1;
layout(binding = 13) uniform samplerCube u_cube_depth_maps_2;
layout(binding = 14) uniform samplerCube u_cube_depth_maps_3;
layout(binding = 15) uniform sampler2D u_skin_map_0;

uniform struct Camera {
  highp vec3 position;
  highp mat4 view;
  highp mat4 view_inversed;
  highp mat4 projection;
  highp mat4 projection_inversed;
  highp float exposure;
  highp float gamma;
  highp float near;
  highp float far;
} camera;

uniform struct Environment {
  highp vec4 background_color;
  highp vec3 ambient_color;
  highp float fog_density;
  highp float fog_gradient;
  highp float mip_count;
  highp int has_env_map;
  highp int lights_count;
  highp int skin_sampler_width;
} env;

uniform struct Frame {
  highp vec3 resolution;
  highp float time;
  highp float time_delta;
  highp int count;
  highp vec4 mouse;
  highp vec4 date;
} frame;

#define LIGHT_TYPE_DIRECTIONAL 0
#define LIGHT_TYPE_POINT 1
#define LIGHT_TYPE_SPOT 2

uniform struct Light {
  int type;
  vec3 color;
  vec3 position;
  vec3 direction;
  vec3 normalized_direction;
  float luminance;
  float range;
  float intensity;
  float inner_cutoff_cos;
  float outer_cutoff_cos;
  int depth_map;
  mat4 shadow_mvp;
} lights[MAX_LIGHTS + 1];

in struct Surface {
  vec4 position;
  vec4 position_related_to_view;
  vec4 position_projected;
  vec3 normal;
  vec2 uv;
  vec4 debug;
  mat4 debugm;
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

#define PI 3.14159265359
#define HALF_PI 1.570796327
#define ONE_OVER_PI 0.3183098861837697
#define LOG2 1.442695
#define SHADOW_BIAS 0.00001
#define MIN_SHADOW_BIAS 0.000001
#define MEDIUMP_FLT_MAX 65504.0
#define saturate(x) clamp(x, 0.00001, 1.0)
#define sq(x) x *x
#define GAMMA 2.2
#define INV_GAMMA 1.0 / GAMMA

// TODO provide normal scale in material
const float NORMAL_SCALE = 0.9;
const float INDIRECT_INTENSITY = 0.6;
const float OCCLUSION_STRENGTH = 1.0;
const float SPECULAR_WEIGHT = 0.6;
const float MIN_VARIANCE = 0.00001;

float pow5(float x) {
  float x2 = x * x;
  return x2 * x2 * x;
}

vec3 permute(vec3 x) {
    return mod(((x*34.0)+1.0)*x, 289.0);
}

float snoise(vec2 v)
{
    const vec4 C = vec4(0.211324865405187,
                        0.366025403784439,
                       -0.577350269189626,
                        0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod(i, 289.0 );
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
        + i.x + vec3(0.0, i1.x, 1.0 ));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

float chebyshev_upperBound(vec2 moments, float t) {
  // One-tailed inequality valid if t > Moments.x
  float p = t <= moments.x ? 1.0 : 0.0;
  // Compute variance.
  float variance = moments.y - sq(moments.x);
  variance = max(variance, MIN_VARIANCE);
  // Compute probabilistic upper bound.
  float d = t - moments.x;
  float p_max = variance / (variance + d * d);
  return max(p, p_max);
}

float shadow_contribution(sampler2D depth_map, vec2 coord,
                          float distance_to_light) {
  // Read the moments from the variance shadow map.
  vec2 moments = texture(depth_map, coord).xy;
  // Compute the Chebyshev upper bound.
  return chebyshev_upperBound(moments, distance_to_light);
}

vec4 fog(vec4 color, float fogDensity, vec4 fogColor, float fogStart, float fogEnd) {
    float fragmentDepth = gl_FragCoord.z;
    float fog = (fragmentDepth - fogStart) / (fogEnd - fogStart);
    fog = clamp(fog, 0.0, 1.0);
    return mix(fogColor, color, fog);
}

/*
float linstep(float min, float max, float v) {
  return clamp((v - min) / (max - min), 0.0, 1.0);
}

float reduce_light_bleeding(float p_max, float Amount) {
  // Remove the [0, Amount] tail and linearly rescale (Amount, 1].
  return linstep(Amount, 1.0, p_max);
}
*/

// Where to split the value. 8 bits works well for most situations.
const float DISTRIBUTE_FACTOR = 256.0;
const float DISTRIBUTE_FACTOR_INV = 1.0 / DISTRIBUTE_FACTOR;

vec4 distribute_precision(vec2 Value, vec2 Moments) {
  // Split precision
  vec2 IntPart;
  vec2 FracPart = modf(Value * DISTRIBUTE_FACTOR, IntPart);
  // Compose outputs to make reconstruction cheap.
  return vec4(IntPart * DISTRIBUTE_FACTOR_INV, FracPart);
}

vec2 recombine_precision(vec4 Value) {
  return (Value.zw * DISTRIBUTE_FACTOR_INV + Value.xy);
}

float sample_shadow(Light light, vec3 N, sampler2D depth_map) {
  vec4 shadow_position = light.shadow_mvp * surface.position;
  vec3 shadow_direction = normalize(light.position - surface.position.xyz);
  vec4 light_space_position = shadow_position / shadow_position.w;
  light_space_position = light_space_position * 0.5 + 0.5;
  float bias =
      max(SHADOW_BIAS * (1.0 - dot(N, shadow_direction)), MIN_SHADOW_BIAS);

  bool out_of_shadow =
      shadow_position.w <= 0.0 ||
      (light_space_position.x < 0.0 || light_space_position.y < 0.0) ||
      (light_space_position.x >= 1.0 || light_space_position.y >= 1.0);

  if (!out_of_shadow) {
    // float shadow_factor = texture(u_depth_texture,
    // v_shadow_light_position.xyz); light_color *= shadow_factor; return
    // shadow_contribution(depth_map, light_space_position.xy,
    // light_space_position.z);

    float shadow_depth = texture(depth_map, light_space_position.xy).r;
    float model_depth = light_space_position.z - bias;
    if (model_depth < shadow_depth) {
      return 1.0;
    }
    return 0.01;
  }
  return 1.0;
}

float sample_shadow(Light light, vec3 N) {
  if (light.depth_map >= 0) {
    if (light.depth_map == 0) {
      return sample_shadow(light, N, u_depth_maps_0);
    }
    if (light.depth_map == 1) {
      return sample_shadow(light, N, u_depth_maps_1);
    }
    if (light.depth_map == 2) {
      return sample_shadow(light, N, u_depth_maps_2);
    }
    if (light.depth_map == 3) {
      return sample_shadow(light, N, u_depth_maps_3);
    }
  }
  return 1.0;
}

vec3 get_light_intensity(Light light, vec3 N, vec3 point_to_light, float distance) {
  float intensity = 0.0;
  if(light.type == LIGHT_TYPE_DIRECTIONAL) {
    intensity = dot(N, -light.normalized_direction) * light.intensity;
  } else if (light.type == LIGHT_TYPE_SPOT){
    float angle = dot(normalize(point_to_light), -light.normalized_direction);
    float luma = light.luminance / (distance * distance);
    intensity = luma * smoothstep(light.outer_cutoff_cos, light.inner_cutoff_cos, angle);
  } else {
    intensity = light.luminance / (distance * distance);
  }
  return intensity * light.color;
}

vec3 calculate_irradiance_spherical_harmonics(const vec3 n) {
  // Irradiance from "Ditch River" IBL
  // (http://www.hdrlabs.com/sibl/archive.html)
  return max(
      vec3(0.754554516862612, 0.748542953903366, 0.790921515418539) +
          vec3(-0.083856548007422, 0.092533500963210, 0.322764661032516) *
              (n.y) +
          vec3(0.308152705331738, 0.366796330467391, 0.466698181299906) *
              (n.z) +
          vec3(-0.188884931542396, -0.277402551592231, -0.377844212327557) *
              (n.x),
      0.0);
}

vec3 get_normal() {
  vec3 N = normalize(surface.normal);
  if (material.has_normal_map > 0.0) {
    vec3 dp1 = dFdx(surface.position.xyz);
    vec3 dp2 = dFdy(surface.position.xyz);
    vec2 duv1 = dFdx(surface.uv);
    vec2 duv2 = dFdy(surface.uv);

    vec3 dp2perp = cross(dp2, N);
    vec3 dp1perp = cross(N, dp1);
    vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
    vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;

    /* construct a scale-invariant frame */
    float invmax = inversesqrt(max(dot(T, T), dot(B, B)));
    mat3 TBN = mat3(T * invmax, B * invmax, N);
    vec3 map = texture(u_normal_map, surface.uv).rgb * 2.007874 - 1.007874;
    N = normalize(TBN * map);
  }
  return N;
}

float D_GGX(float alpha_roughness, float NoH) {
  // Walter et al. 2007, "Microfacet Models for Refraction through Rough
  // Surfaces"
  float oneMinusNoHSquared = 1.0 - NoH * NoH;
  float a = NoH * alpha_roughness;
  float k = alpha_roughness / (oneMinusNoHSquared + a * a);
  float d = k * k * (1.0 / PI);
  return d;
}

float V_SmithGGXCorrelated(float a2, float NoV, float NoL,
                           float ggx_factor_const) {
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
  float view_scatter = F_Schlick(1.0, f90, NoV);
  return light_scatter * view_scatter * ONE_OVER_PI;
}

float Fd_Lambert() { return ONE_OVER_PI; }

vec2 get_prefiltered_dfg_karis(float roughness, float NoV) {
  // Karis 2014, "Physically Based Material on Mobile"
  const vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
  const vec4 c1 = vec4(1.0, 0.0425, 1.040, -0.040);

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

vec3 linearTosRGB(vec3 color) { return pow(color, vec3(INV_GAMMA)); }

vec3 sRGBToLinear(vec3 srgbIn) { return vec3(pow(srgbIn.xyz, vec3(GAMMA))); }

vec3 calculate_specular_indirect(vec3 V, vec3 N, float roughness) {
  float lod = roughness * env.mip_count;
  vec3 reflection = -normalize(reflect(V, N));
  vec3 specular =  env.background_color.rgb; 
  if(env.has_env_map > 0) {
    textureLod(u_ggx_map, reflection, lod).rgb;
  }
  return specular;
}

vec3 calculare_lambertian_brdf(vec3 f0, vec3 diffuseColor, float specularWeight,
                               float VoH) {
  vec3 F = F_Schlick(f0, VoH);
  // https://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/
  return (1.0 - specularWeight * F) * diffuseColor * ONE_OVER_PI;
}

vec3 calculate_specular_brdf(vec3 f0, float alpha_roughness, float a2,
                             float specularWeight, float VoH, float NoL,
                             float NoV, float NoH, float ggx_factor_const) {
  vec3 F = F_Schlick(f0, VoH);
  float Vis = V_SmithGGXCorrelated(NoL, NoV, a2, ggx_factor_const);
  float D = D_GGX(alpha_roughness, NoH);

  return specularWeight * F * Vis * D;
}

vec3 get_normal(vec3 v) {
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
  if (gl_FrontFacing == false) {
    t *= -1.0;
    b *= -1.0;
    ng *= -1.0;
  }

  // Compute pertubed normals:
  if (material.has_normal_map > 0.0) {
    n = texture(u_normal_map, UV).rgb * 2.0 - vec3(1.0);
    n *= vec3(NORMAL_SCALE, NORMAL_SCALE, 1.0);
    n = mat3(t, b, ng) * normalize(n);
  } else {
    n = ng;
  }
  return n;
}

void light_pbr(vec3 N, vec3 V, vec3 base_color, float metallic, float roughness,
               float ao, float reflectance, out vec3 f_specular, out vec3 f_diffuse) {
  vec3 f0 = 0.16 * reflectance * reflectance * (1.0 - metallic) + base_color.rgb * metallic;
  vec3 albedo = mix(base_color.rgb * (vec3(1.0) - f0), vec3(0), metallic);
  // TODO: use reflectance
  // float reflectance = max(max(f0.r, f0.g), f0.b);

  float alpha_roughness = roughness * roughness;
  float a2 = alpha_roughness * alpha_roughness;
  float NoV = abs(dot(N, V)) + 1e-5;
  float ggx_factor_const = sqrt((NoV - a2 * NoV) * NoV + a2);

  // Calculates indirect lights
  f_diffuse = env.ambient_color + (INDIRECT_INTENSITY *
               calculate_irradiance_spherical_harmonics(N) * Fd_Lambert() *
               albedo);
  vec2 dfg = get_prefiltered_dfg_karis(roughness, NoV);
  vec3 specular_color = f0 * material.specular_color * dfg.x + dfg.y;
  f_specular += INDIRECT_INTENSITY * specular_color *
                calculate_specular_indirect(V, N, roughness);

  // Adds occlusion
  f_diffuse = mix(f_diffuse, f_diffuse * ao, OCCLUSION_STRENGTH);
  f_specular = mix(f_specular, f_specular * ao, OCCLUSION_STRENGTH);

  int lights_count = min(MAX_LIGHTS, env.lights_count);
  for (int i = 0; i < lights_count; i++) {
    vec3 point_to_light = lights[i].position - surface.position.xyz;
    float distance = length(point_to_light);
    vec3 L = normalize(point_to_light);
    vec3 R = normalize(reflect(-L, N));
    vec3 H = normalize(V + L);
    float NoV = abs(dot(N, V)) + 1e-5;
    float NoL = saturate(dot(N, L));
    float NoH = saturate(dot(N, H));
    //float LoH = saturate(dot(L, H));
    float VoH = saturate(dot(V, H));
    // float attenuation = lights[i].intensity / dot(lights[i].attenuation,
    // vec3(1.0, distance, distance * distance));
    vec3 intensity = get_light_intensity(lights[i], N, point_to_light, distance);

    intensity *= sample_shadow(lights[i], N);

    f_diffuse += intensity * NoL *
                 calculare_lambertian_brdf(f0, albedo, SPECULAR_WEIGHT, VoH);
    f_specular +=
        intensity * NoL *
        calculate_specular_brdf(f0, alpha_roughness, a2, SPECULAR_WEIGHT, VoH,
                                NoL, NoV, NoH, ggx_factor_const);
  }
}

void light_normal(vec3 N, vec3 V, float shininess, out vec3 f_specular, out vec3 f_diffuse) {
  f_diffuse = env.ambient_color;
  int lights_count = min(MAX_LIGHTS, env.lights_count);
  for (int i = 0; i < lights_count; i++) {
    vec3 point_to_light = lights[i].position - surface.position.xyz;
    float distance = length(point_to_light);
    vec3 L = normalize(point_to_light);
    float NoL = saturate(dot(N, L));
    
    vec3 intensity = get_light_intensity(lights[i], N, point_to_light, distance);
    intensity *= sample_shadow(lights[i], N);
    if(lights[i].type != LIGHT_TYPE_DIRECTIONAL) {
      vec3 R = normalize(reflect(-L, N));
      float RoV = dot(R, V);
      f_diffuse += intensity * NoL;
      float coefficient = pow(max(RoV, 0.0), shininess);
      f_specular += intensity * coefficient;
    } else {
      f_diffuse += intensity;
    }
  }
}

vec3 NORMAL;
vec4 COLOR;

$MAIN_FUNCTION$

layout(location = 0) out vec4 OUT_COLOR;
layout(location = 1) out vec3 OUT_NORMAL;

void main() {
  COLOR = vec4(material.base_color, material.opacity);
  if (material.has_albedo_map > 0.0) {
    COLOR = COLOR * texture(u_albedo_map, surface.uv);
  }

  float fog_amount = 0.0;
  if(env.fog_density > 0.0) {
    float distance = length(surface.position_related_to_view);
    fog_amount = exp2(-env.fog_density * env.fog_density * distance * distance * LOG2);
    fog_amount = clamp(fog_amount, 0., 1.);
  } else if (COLOR.a < 0.01) {
    discard;
  }

  float metallic = material.metallic;
  if (material.has_metallic_map > 0.0) {
    metallic *= texture(u_metallic_map, surface.uv).b;
  }

  float roughness = material.roughness;
  if (material.has_roughness_map > 0.0) {
    roughness *= texture(u_roughness_map, surface.uv).g;
  }

  float ao = material.ao;
  if (material.has_ao_map > 0.0) {
    ao *= texture(u_ao_map, surface.uv).r;
  }

  vec3 V = normalize(camera.position - surface.position.xyz);
  vec3 N = get_normal();

  // Adds emissive color
  vec3 f_emissive = material.emissive_color;
  if (material.has_emissive_map > 0.0) {
    f_emissive = texture(u_emissive_map, surface.uv).rgb;
  }

  vec3 f_specular = vec3(0.0);
  vec3 f_diffuse = vec3(0.0);

  if (roughness > 0.0 || metallic > 0.0) {
    light_pbr(
      N, 
      V, 
      sRGBToLinear(COLOR.rgb), 
      metallic, 
      roughness, 
      ao,
      material.reflectance,
      f_specular, 
      f_diffuse
    );
    COLOR.rgb = f_emissive + f_diffuse + f_specular;  
    COLOR.rgb = tonemap_aces(COLOR.rgb);
    //COLOR.rgb = linearTosRGB(COLOR.rgb);
  } else {
    light_normal(N, V, material.reflectance * 255.0, f_specular, f_diffuse);
    COLOR.rgb = COLOR.rgb * (f_emissive + f_diffuse + f_specular);
  }

  NORMAL = N;
  $MAIN_FUNCTION_CALL$

  if(fog_amount > 0.0) {
    COLOR = mix(env.background_color, COLOR, fog_amount);
  }
  
  OUT_NORMAL = NORMAL.xyz;
  OUT_COLOR = COLOR;  
}

