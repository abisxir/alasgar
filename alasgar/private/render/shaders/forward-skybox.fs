$SHADER_PROFILE$
precision highp float;

uniform samplerCube u_skybox;

in vec3 v_coord;

// we need to declare an output for the fragment shader
out vec4 out_color;

void main() {
  out_color = texture(u_skybox, v_coord);
}