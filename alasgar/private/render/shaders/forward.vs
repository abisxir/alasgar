$SHADER_PROFILE$
precision highp float;
precision highp int;

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec4 in_uv;
layout(location = 3) in vec4 in_bone;
layout(location = 4) in vec4 in_weight;
layout(location = 5) in mat4 in_model;
layout(location = 9) in uvec4 in_material;
layout(location = 10) in vec4 in_sprite;
layout(location = 11) in vec4 in_skin;

layout(binding = 15) uniform sampler2D u_skin_map_0;

// Camera
uniform struct Camera {
  vec3 position;
  mat4 view;
  mat4 view_inversed;
  mat4 projection;
  mat4 projection_inversed;
  float exposure;
  float gamma;
  float near;
  float far;
} camera;

uniform struct Environment {
  vec4 background_color;
  vec3 ambient_color;
  float fog_density;
  float fog_gradient;
  float mip_count;
  int lights_count;
  int skin_sampler_width;
} env;

uniform struct Frame {
  vec3 resolution;
  float time;
  float time_delta;
  int count;
  vec4 mouse;
  vec4 date;
} frame;

out struct Surface {
  vec4 position;
  vec4 position_related_to_view;
  vec4 position_projected;
  vec3 normal;
  vec2 uv;
  vec4 debug;
  mat4 debugm;
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

#define ALBEDO_MAP_FLAG 1u
#define NORMAL_MAP_FLAG 2u
#define METALLIC_MAP_FLAG 4u
#define ROUGHNESS_MAP_FLAG 8u
#define AO_MAP_FLAG 16u
#define EMISSIVE_MAP_FLAG 32u

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

vec4 sample_skin(int offset) {
  int y = offset / env.skin_sampler_width;
  int x = offset % env.skin_sampler_width;
  return texelFetch(u_skin_map_0, ivec2(x, y), 0).rgba;
}

mat4 get_bone_transform(float index) {
  // Calculate the texel coordinates for the matrix data, taking into account
  // the offset
  int start = int(in_skin[1]) + int(index) * 4;
  return mat4(
    sample_skin(start),
    sample_skin(start + 1),
    sample_skin(start + 2),
    sample_skin(start + 3)
  );
}

mat4 apply_skin_transform(mat4 model) {
  mat4 final_transform = model;
  if (in_skin[0] > 0.0) {
    final_transform = 
      get_bone_transform(in_bone[0]) * in_weight[0] +
      get_bone_transform(in_bone[1]) * in_weight[1] +
      get_bone_transform(in_bone[2]) * in_weight[2] +
      get_bone_transform(in_bone[3]) * in_weight[3];
  }
  surface.debugm = final_transform;
  return final_transform;
}

void main() {
  extract_material_data();

  vec2 frame_size = in_sprite.xy;
  vec2 frame_offset = in_sprite.zw;

  vec4 position = vec4(in_position, 1.0);

  surface.debug = vec4(in_bone);

  mat4 model = apply_skin_transform(in_model);
  surface.position = model * position;
  surface.normal = (model * vec4(in_normal, 0.0)).xyz;
  //mat4 normal_matrix = transpose(inverse(in_model));
  //surface.normal = (normal_matrix * vec4(in_normal, 0.0)).xyz;

  surface.debugm[0] = in_bone;
  surface.debugm[1] = in_weight;
  surface.debugm[3] = in_skin;

  if (frame_size.x > 0.0) {
    surface.uv = (in_uv.xy * frame_size) + frame_offset;
  } else {
    surface.uv = in_uv.xy;
  }

  surface.position_related_to_view = camera.view * surface.position;
  surface.position_projected = camera.projection * surface.position_related_to_view;

  $MAIN_FUNCTION_CALL$

  gl_Position = surface.position_projected;
}
