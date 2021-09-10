#version 300 es
precision mediump float;

in float v_depth;

layout(location = 0) out vec2 o_color;

void main() 
{
    float depth2 = pow(v_depth, 2.0);

    // approximate the spatial average of vDepth^2
    float dx = dFdx(v_depth);
    float dy = dFdy(v_depth);
    float depth2_avg = depth2 + 0.50 * (dx*dx + dy*dy);

    // depth saved in red channel while average depth^2 is
    // stored in the green channel
    //o_color = vec2(v_depth, depth2_avg);    
    o_color = vec2(v_depth, depth2_avg);
}
