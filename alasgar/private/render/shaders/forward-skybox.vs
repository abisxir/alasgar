$SHADER_PROFILE$
precision highp float;

layout(location = 0) in vec3 in_position;

out vec3 v_coord;

uniform mat4 u_projection;
uniform mat4 u_view;

void main() {
  v_coord = in_position;
  gl_Position = u_projection * u_view * vec4(in_position, 1.0);
}

