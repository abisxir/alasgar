$SHADER_PROFILE$
precision highp float;

layout(location = 0) in vec3 in_position;

out vec3 v_coord;

uniform mat4 u_projection;
uniform mat4 u_view;

void main() {
  mat4 inverseProjection = inverse(u_projection);
  mat3 inverseModelview = transpose(mat3(u_projection));

  vec3 unprojected = (inverseProjection * vec4(in_position, 1.0)).xyz;

  //transfrom from the view space back to the world space
  //and use it as a sampling vector
  v_coord = inverseModelview * unprojected;  

  gl_Position = vec4(in_position, 1.0);
}

