$SHADER_PROFILE$
precision mediump float;

uniform sampler2D frame_buffer_texture;

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

// Custom shader params
uniform highp vec3 iResolution;
uniform highp float iTime;
uniform highp float iTimeDelta;
uniform highp float iFrame;
uniform highp vec4 iMouse;
uniform highp vec4 iDate;

vec4 iColor;
$MAIN_FUNCTION$

in vec2 v_uv;

out vec4 out_fragment_color;

void main() 
{
    out_fragment_color = texture(frame_buffer_texture, v_uv);
    $MAIN_FUNCTION_CALL$
}
