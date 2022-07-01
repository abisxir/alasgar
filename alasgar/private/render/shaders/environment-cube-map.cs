$SHADER_PROFILE$

const float PI = 3.141592;
const float TwoPI = 6.283184;


layout(local_size_x=16, local_size_y=16, local_size_z=1) in;
layout(rgba16f, binding=0) writeonly uniform mediump imageCube outputTexture;
layout(binding=0) uniform mediump sampler2D inputTexture;

// Calculate normalized sampling direction vector based on current fragment coordinates (gl_GlobalInvocationID.xyz).
// This is essentially "inverse-sampling": we reconstruct what the sampling vector would be if we wanted it to "hit"
// this particular fragment in a cubemap.
// See: OpenGL core profile specs, section 8.13.
vec3 getSamplingVector()
{
    vec2 xy = vec2(gl_GlobalInvocationID.xy);
    int z = int(gl_GlobalInvocationID.z);
    vec2 st = xy / vec2(imageSize(outputTexture));
    vec2 uv = 2.0 * vec2(st.x, 1.0 - st.y) - vec2(1.0);

    vec3 ret;
	// Select vector based on cubemap face index.
    // Sadly 'switch' doesn't seem to work, at least on NVIDIA.
    if(z == 0)      ret = vec3(1.0,  uv.y, -uv.x);
    else if(z == 1) ret = vec3(-1.0, uv.y,  uv.x);
    else if(z == 2) ret = vec3(uv.x, 1.0, -uv.y);
    else if(z == 3) ret = vec3(uv.x, -1.0, uv.y);
    else if(z == 4) ret = vec3(uv.x, uv.y, 1.0);
    else if(z == 5) ret = vec3(-uv.x, uv.y, -1.0);
    return normalize(ret);
}

void main()
{
	vec3 v = getSamplingVector();

	// Convert Cartesian direction vector to spherical coordinates.
	float phi   = atan(v.z, v.x);
	float theta = acos(v.y);

	// Sample equirectangular texture.
	vec4 color = texture(inputTexture, vec2(phi/TwoPI, theta/PI));

	// Write out color to output cubemap.
	imageStore(outputTexture, ivec3(gl_GlobalInvocationID), color);
}