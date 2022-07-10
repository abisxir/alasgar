$SHADER_PROFILE$
precision highp float;

layout(location = 0) in vec2 in_position;
layout(location = 1) in vec2 in_uv;

uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform float iFrame;
uniform vec4 iMouse;
uniform vec4 iDate;

out vec2 v_uv;
out vec2 v_frag_coord;
out vec2 v_rgbNW;
out vec2 v_rgbNE;
out vec2 v_rgbSW; 
out vec2 v_rgbSE;
out vec2 v_rgbM;

void main() {
    v_uv = in_uv;
    v_frag_coord = in_uv * iResolution.xy;
    v_rgbNW = (v_frag_coord + vec2(-1.0, -1.0)) / iResolution.xy;
    v_rgbNE = (v_frag_coord + vec2(1.0, -1.0)) / iResolution.xy;
    v_rgbSW = (v_frag_coord + vec2(-1.0, 1.0)) / iResolution.xy;
    v_rgbSE = (v_frag_coord + vec2(1.0, 1.0)) / iResolution.xy;
    v_rgbM = v_frag_coord / iResolution.xy;
    gl_Position = vec4(in_position, 0.0, 1.0);
}
