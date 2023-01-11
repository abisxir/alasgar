$SHADER_PROFILE$
precision highp float;

layout(binding = 0) uniform sampler2D iChannel0;
layout(binding = 1) uniform sampler2D iChannel1;
layout(binding = 2) uniform sampler2D iChannel2;
layout(binding = 3) uniform sampler2D iChannel3;
layout(binding = 4) uniform sampler2D iChannel4;

// Custom shader params
uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform float iFrame;
uniform vec4 iMouse;
uniform vec4 iDate;

in vec2 UV;
out vec4 COLOR;
$MAIN_FUNCTION$
void main() 
{
    COLOR = texture(iChannel0, UV);
    $MAIN_FUNCTION_CALL$
}
