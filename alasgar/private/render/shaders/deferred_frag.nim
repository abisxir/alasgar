var source* = """
#version 300 es
precision mediump float;
//precision mediump sampler2DShadow;

uniform sampler2D u_diffuse_texture;
uniform sampler2D u_normal_texture;

// Model
in vec2 v_uv;
in vec3 v_normal;
in vec4 v_fragment_position;
in vec3 v_light_color;
in float v_visibilty;
in vec4 v_fog_color;
in vec4 v_shadow_position;
// Material
in vec4 v_diffuse_color;
in float v_opacity;
in vec3 v_specular_color;
in float v_shininess;
in float v_has_texture;
in float v_has_normal;

layout (location = 0) out vec3 out_position;
layout (location = 1) out vec4 out_normal;
layout (location = 2) out vec4 out_diffuse;
//layout (location = 3) out vec3 out_specular;
//layout (location = 4) out vec2 out_shadow;

void main() 
{
    out_position = v_fragment_position.xyz;
    out_normal = vec4(v_normal, v_specular_color.r);
    out_diffuse = v_diffuse_color;
    if(v_has_texture > 0.0) {
        out_diffuse = texture(u_diffuse_texture, v_uv);
    }
    if(out_diffuse.a < 0.01) {
        discard;
    } else {
        vec4 light_color = vec4(v_light_color, 1.0);

        out_diffuse *= light_color;

        if(v_visibilty >= 0.0) {
            out_diffuse = mix(v_fog_color, out_diffuse, v_visibilty);
        }
    }

}
"""