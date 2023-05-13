$SHADER_PROFILE$
precision highp float;

#define PI                  3.14159265359
#define TWO_PI              6.28318530718

layout(binding = 0) uniform sampler2D u_skybox;

// Comes from vertex shader
in vec3 v_coord;
// We need to declare an output for the fragment shader
out vec4 out_color;

vec2 envMapEquirect(vec3 wcNormal, float flipEnvMap) {
  float phi = acos(-wcNormal.y);
  float theta = atan(flipEnvMap * wcNormal.x, wcNormal.z) + PI;
  return vec2(theta / TWO_PI, phi / PI);
}

vec2 envMapEquirect(vec3 wcNormal) {
    return envMapEquirect(wcNormal, -1.0);
}

void main() {
  vec3 N = normalize(v_coord);
  out_color = texture2D(u_skybox, envMapEquirect(N));
}