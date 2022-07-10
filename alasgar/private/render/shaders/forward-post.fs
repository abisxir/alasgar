$SHADER_PROFILE$
precision highp float;

uniform sampler2D frame_buffer_texture;

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

// Custom shader params
uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform float iFrame;
uniform vec4 iMouse;
uniform vec4 iDate;
uniform int u_fxaa;
uniform float u_fxaa_span_max;
uniform float u_fxaa_reduce_mul;
uniform float u_fxaa_reduce_min;

vec4 iColor;
$MAIN_FUNCTION$

in vec2 v_uv;
in vec2 v_frag_coord;
in vec2 v_rgbNW;
in vec2 v_rgbNE;
in vec2 v_rgbSW; 
in vec2 v_rgbSE;
in vec2 v_rgbM;

out vec4 out_fragment_color;

vec4 fxaa(
  sampler2D tex, 
  vec2 fragCoord, 
  vec2 resolution
) {
	vec4 color;
	mediump vec2 inverseVP = vec2(1.0 / resolution.x, 1.0 / resolution.y);
	vec3 rgbNW = texture(tex, v_rgbNW).xyz;
	vec3 rgbNE = texture(tex, v_rgbNE).xyz;
	vec3 rgbSW = texture(tex, v_rgbSW).xyz;
	vec3 rgbSE = texture(tex, v_rgbSE).xyz;
	vec4 texColor = texture(tex, v_rgbM);
	vec3 rgbM  = texColor.xyz;
	vec3 luma = vec3(0.299, 0.587, 0.114);
	float lumaNW = dot(rgbNW, luma);
	float lumaNE = dot(rgbNE, luma);
	float lumaSW = dot(rgbSW, luma);
	float lumaSE = dot(rgbSE, luma);
	float lumaM  = dot(rgbM,  luma);
	float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
	float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));
  
	mediump vec2 dir;
	dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
	dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

	float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) *
						(0.25 * u_fxaa_reduce_mul), u_fxaa_reduce_min);
  
	float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
	dir = min(vec2(u_fxaa_span_max, u_fxaa_span_max),
			max(vec2(-u_fxaa_span_max, -u_fxaa_span_max),
			dir * rcpDirMin)) * inverseVP;
  
	vec3 rgbA = 0.5 * (
		texture(tex, fragCoord * inverseVP + dir * (1.0 / 3.0 - 0.5)).xyz +
		texture(tex, fragCoord * inverseVP + dir * (2.0 / 3.0 - 0.5)).xyz);
	vec3 rgbB = rgbA * 0.5 + 0.25 * (
		texture(tex, fragCoord * inverseVP + dir * -0.5).xyz +
		texture(tex, fragCoord * inverseVP + dir * 0.5).xyz);

	float lumaB = dot(rgbB, luma);
	if ((lumaB < lumaMin) || (lumaB > lumaMax))
		color = vec4(rgbA, texColor.a);
	else
		color = vec4(rgbB, texColor.a);
	return color;
}

void main() 
{
	if(u_fxaa > 0) {
		out_fragment_color = fxaa(frame_buffer_texture, v_frag_coord, iResolution.xy);
	} else {
		out_fragment_color = texture(frame_buffer_texture, v_uv);
	}

    $MAIN_FUNCTION_CALL$
}
