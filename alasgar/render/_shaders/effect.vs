$SHADER_PROFILE$
precision highp float;

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

uniform struct Frame {
  vec3 resolution;
  float time;
  float time_delta;
  highp int count;
  vec4 mouse;
  vec4 date;
} frame;

vec4 POSITION;

out vec2 UV;

$MAIN_FUNCTION$

void main(void) 
{
    float x = float((gl_VertexID & 1) << 2);
    float y = float((gl_VertexID & 2) << 1);
    UV.x = x * 0.5;
    UV.y = y * 0.5;
    POSITION = vec4(x - 1.0, y - 1.0, 0.0, 1.0);
    $MAIN_FUNCTION_CALL$
    gl_Position = POSITION;
}