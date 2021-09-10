var source* = """
#version 300 es
precision lowp float;

struct Light {
    vec3 position;
    vec3 color;
    
    float linear;
    float quadratic;
};

const int NR_LIGHTS = 32;

uniform sampler2D u_position_texture;
uniform sampler2D u_normal_texture;
uniform sampler2D u_albedo_texture;
uniform sampler2D u_specular_texture;
//uniform sampler2D u_shadow_texture;

uniform Light lights[NR_LIGHTS];
uniform int u_max_point_light;
uniform vec3 u_view_position;

in vec2 v_uv;

out vec4 out_fragment_color;

void main() 
{
    vec3 position = texture(u_position_texture, v_uv).rgb;
    vec3 normal = texture(u_normal_texture, v_uv).rgb;
    vec4 albedo = texture(u_albedo_texture, v_uv);
    float specular = texture(u_normal_texture, v_uv).a;

    // then calculate lighting as usual
    vec3 lighting  = albedo.xyz;// * 0.1; // hard-coded ambient component
    vec3 view_dir  = normalize(u_view_position - position);
    int light_count = min(u_max_point_light, NR_LIGHTS);
    for(int i = 0; i < light_count; ++i)
    {
        // diffuse
        vec3 light_dir = normalize(lights[i].position - position);
        vec3 diffuse = max(dot(normal, light_dir), 0.0) * albedo.xyz * lights[i].color;

        // specular
        vec3 halfway_dir = normalize(light_dir + view_dir);  
        float spec = pow(max(dot(normal, halfway_dir), 0.0), 16.0);
        vec3 specular = lights[i].color * spec * specular;
        // attenuation
        float distance = length(lights[i].position - position);
        float attenuation = 1.0 / (1.0 + lights[i].linear * distance + lights[i].quadratic * distance * distance);
        diffuse *= attenuation;
        specular *= attenuation;
        lighting += diffuse + specular;        
    }
    out_fragment_color = vec4(lighting, albedo.a);
}
"""