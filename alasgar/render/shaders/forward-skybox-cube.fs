$SHADER_PROFILE$
precision highp float;

layout(binding = 0) uniform samplerCube u_skybox;

uniform float u_environment_intensity;
uniform float u_mip_count;

in vec3 v_dir;

// we need to declare an output for the fragment shader
out vec4 out_color;

void main() {
  out_color = textureLod(u_skybox, normalize(v_dir), u_mip_count * (1.0 - u_environment_intensity));
}