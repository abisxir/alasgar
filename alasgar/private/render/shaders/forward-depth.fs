$SHADER_PROFILE$
precision mediump float;

in float v_depth;

layout(location = 0) out vec2 o_color;

vec2 compute_moments(float depth) {   
    // Compute partial derivatives of depth.    
    float dx = dFdx(depth);   
    float dy = dFdy(depth);   
    // Compute second moment over the pixel extents.   
    float y = depth * depth + 0.25 * (dx * dx + dy * dy);   
    return vec2(depth, y);
} 

void main() 
{
    o_color = compute_moments(v_depth);
}
