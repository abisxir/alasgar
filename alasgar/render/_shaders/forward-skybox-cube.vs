$SHADER_PROFILE$
precision highp float;

layout(location = 0) in vec3 in_position;

out vec3 v_dir;

uniform mat4 u_projection;
uniform mat4 u_view;
uniform mat4 u_model;

void main() {
  v_dir = in_position;
  vec4 pos = u_projection * u_view * vec4(in_position, 1.0);
  gl_Position = pos;
}

