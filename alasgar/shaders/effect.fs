$SHADER_PROFILE$
precision highp float;

layout(binding = 0) uniform sampler2D channel0;
layout(binding = 1) uniform sampler2D channel1;
layout(binding = 2) uniform sampler2D channel2;
layout(binding = 3) uniform sampler2D channel3;
layout(binding = 4) uniform sampler2D color_channel;
layout(binding = 5) uniform sampler2D normal_channel;
layout(binding = 6) uniform sampler2D depth_channel;
layout(binding = 7) uniform sampler2D reserved_channel;

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

in vec2 UV;
out vec4 COLOR;

vec3 permute(vec3 x) {
    return mod(((x*34.0)+1.0)*x, 289.0);
}

float snoise(vec2 v)
{
    const vec4 C = vec4(0.211324865405187,
                        0.366025403784439,
                       -0.577350269189626,
                        0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod(i, 289.0 );
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
        + i.x + vec3(0.0, i1.x, 1.0 ));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

vec3 get_normal(vec2 uv) {
  return texture(normal_channel, uv).xyz;
}

vec3 get_normal() {
  return get_normal(UV);
}

float get_depth(vec2 coord) {
  float depth = texture(depth_channel, coord).r;
  return (depth * 2.0 - 1.0) * (camera.far - camera.near);
}

float get_depth() {
  return get_depth(UV);
}

vec4 get_color(vec2 uv) {
  return texture(color_channel, uv);
}

vec4 position_from_depth(vec2 coord)
{
    // Get the depth value for this pixel
    float z = texture(depth_channel, coord).r;  
    // Get x/w and y/w from the viewport position
    float x = coord.x * 2. - 1.;
    float y = (1. - coord.y) * 2. - 1.;
    vec4 projected_pos = vec4(x, y, z, 1.);

    // Transform by the inverse projection matrix
    vec4 position_in_view_space = camera.projection_inversed * projected_pos;

    // Divide by w to get the view-space position
    return position_in_view_space / position_in_view_space.w;  
}


vec3 get_position(vec2 uv) {
  vec4 pos = camera.view_inversed * position_from_depth(uv);
  return pos.xyz;
}

vec3 get_position() {
  return get_position(UV);
}

float digit_bin( const int x )
{
    return x==0?480599.0:x==1?139810.0:x==2?476951.0:x==3?476999.0:x==4?350020.0:x==5?464711.0:x==6?464727.0:x==7?476228.0:x==8?481111.0:x==9?481095.0:0.0;
}

float print_value( vec2 vStringCoords, float fValue, float fMaxDigits, float fDecimalPlaces )
{       
    if ((vStringCoords.y < 0.0) || (vStringCoords.y >= 1.0)) return 0.0;
    
    bool bNeg = ( fValue < 0.0 );
	fValue = abs(fValue);
    
	float fLog10Value = log2(abs(fValue)) / log2(10.0);
	float fBiggestIndex = max(floor(fLog10Value), 0.0);
	float fDigitIndex = fMaxDigits - floor(vStringCoords.x);
	float fCharBin = 0.0;
	if(fDigitIndex > (-fDecimalPlaces - 1.01)) {
		if(fDigitIndex > fBiggestIndex) {
			if((bNeg) && (fDigitIndex < (fBiggestIndex+1.5))) fCharBin = 1792.0;
		} else {		
			if(fDigitIndex == -1.0) {
				if(fDecimalPlaces > 0.0) fCharBin = 2.0;
			} else {
                float fReducedRangeValue = fValue;
                if(fDigitIndex < 0.0) { fReducedRangeValue = fract( fValue ); fDigitIndex += 1.0; }
				float fDigitValue = (abs(fReducedRangeValue / (pow(10.0, fDigitIndex))));
                fCharBin = digit_bin(int(floor(mod(fDigitValue, 10.0))));
			}
        }
	}
    return floor(mod((fCharBin / pow(2.0, floor(fract(vStringCoords.x) * 4.0) + (floor(vStringCoords.y * 5.0) * 4.0))), 2.0));
}


$MAIN_FUNCTION$

void main() 
{
    COLOR = texture(color_channel, UV);

    /*
    vec2 fragCoord = UV.xy * frame.resolution.xy;
    vec2 point = (frame.mouse.xy / frame.resolution.xy);
		float fDigits = 1.0;
		float fDecimalPlaces = 3.0;
    vec2 vFontSize = vec2(14.0, 30.0);
		float fValue1 = get_normal(point).x;
		float fIsDigit1 = print_value((fragCoord - vec2(frame.mouse.x, frame.mouse.y) + vec2(-50.0, 0.0)) / vFontSize, fValue1, fDigits, fDecimalPlaces);
		COLOR.rgb = mix( COLOR.rgb, vec3(1.0, 1.0, 1.0), fIsDigit1);
    float fValue2 = get_normal(point).y;
		float fIsDigit2 = print_value((fragCoord - vec2(frame.mouse.x, frame.mouse.y) + vec2(-150.0, 0.0)) / vFontSize, fValue2, fDigits, fDecimalPlaces);
		COLOR.rgb = mix( COLOR.rgb, vec3(1.0, 1.0, 1.0), fIsDigit2);
    float fValue3 = get_normal(point).z;
		float fIsDigit3 = print_value((fragCoord - vec2(frame.mouse.x, frame.mouse.y) + vec2(-250.0, 0.0)) / vFontSize, fValue3, fDigits, fDecimalPlaces);
		COLOR.rgb = mix( COLOR.rgb, vec3(1.0, 1.0, 1.0), fIsDigit3);
    */

    $MAIN_FUNCTION_CALL$
}
