#define LIGHT_DIRECTIONAL 0
#define LIGHT_POINT 1
#define LIGHT_SPOT 2

struct Light {
    int TYPE;
    vec3 POSITION;
    vec3 DIRECTION;
    vec3 COLOR;
    float INTENSITY;
    float INNER_CUTOFF;
    float OUTER_CUTOFF;
    float ATTENUATION;
    float LUMINANCE;
};

struct Material {
    vec3 AMBIENT;
    vec3 ALBEDO;
    vec3 SPECULAR;
    vec3 EMISSIVE;
    float METALLIC;
    float ROUGHNESS;
    float REFLECTANCE;
    float AMBIENT_OCCLUSION;
};

struct Vertex {
    vec3 POSITION;
    vec3 NORMAL;
    vec2 UV;
};

struct Camera {
    vec3 POSITION;
    vec3 DIRECTION;
    vec3 UP;
    vec3 RIGHT;
    float FOV;
    float NEAR;
    float FAR;
    float ASPECT;
    float EXPOSURE;
};

uniform Camera CAMERA;
uniform Light LIGHTS[8];
uniform Material MATERIAL;
uniform sampler2D ALBEDO_MAP;
uniform sampler2D NORMAL_MAP;
uniform sampler2D ROUGHNESS_MAP;
uniform sampler2D METALLIC_MAP;
uniform sampler2D AMBIENT_OCCLUSION_MAP;
uniform sampler2D IRRADIANCE_MAP;
uniform sampler2D PREFILTER_MAP;
uniform sampler2D BRDF_LUT;
uniform samplerCube ENVIRONMENT_MAP;


in Vertex VERTEX;

out vec3 COLOR;

vec3 getNormal() {
    vec3 dp1 = dFdx(VERTEX.POSITION);
    vec3 dp2 = dFdy(VERTEX.POSITION);
    vec2 duv1 = dFdx(VERTEX.UV);
    vec2 duv2 = dFdy(VERTEX.UV);
    vec3 dp2perp = cross(dp2, VERTEX.NORMAL);
    vec3 dp1perp = cross(VERTEX.NORMAL, dp1);
    vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
    vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;
    float invmax = inversesqrt(max(dot(T, T), dot(B, B)));
    vec3 N = texture(NORMAL_MAP, VERTEX.UV).xyz * 2.0 - 1.0; //normalize(T * invmax);
    return normalize(mat3(T, B, VERTEX.NORMAL) * N);
}

vec3 getAlbedo() {
    return texture(ALBEDO_MAP, VERTEX.UV).rgb;
}

float getRoughness() {
    return texture(ROUGHNESS_MAP, VERTEX.UV).r;
}

float getMetallic() {
    return texture(METALLIC_MAP, VERTEX.UV).r;
}

float getAmbientOcclusion() {
    return texture(AMBIENT_OCCLUSION_MAP, VERTEX.UV).r;
}

vec3 getSpecular() {
    return MATERIAL.SPECULAR;
}

vec3 getEmissive() {
    return MATERIAL.EMISSIVE;
}

vec3 getAmbient() {
    return MATERIAL.AMBIENT;
}

vec3 getIrradiance() {
    return texture(IRRADIANCE_MAP, VERTEX.NORMAL).rgb;
}

vec3 getPrefilteredRadiance() {
    float roughness = getRoughness();
    vec3 N = getNormal();
    vec3 R = reflect(-CAMERA.DIRECTION, N);
    float mip = roughness * (float(MIPMAP_LEVELS) - 1.0);
    int mip0 = int(mip);
    int mip1 = mip0 + 1;
    float factor = mip - float(mip0);
    vec3 color0 = texture(PREFILTER_MAP, vec3(R, float(mip0))).rgb;
    vec3 color1 = texture(PREFILTER_MAP, vec3(R, float(mip1))).rgb;
    vec3 color = mix(color0, color1, factor);
    return color;
}

vec2 getBRDF() {
    float roughness = getRoughness();
    float NoV = max(dot(VERTEX.NORMAL, CAMERA.DIRECTION), 0.0);
    return texture(BRDF_LUT, vec2(NoV, roughness)).rg;
}

vec3 getDiffuse() {
    vec3 irradiance = getIrradiance();
    vec3 radiance = getPrefilteredRadiance();
    vec2 brdf = getBRDF();
    float NoV = max(dot(VERTEX.NORMAL, CAMERA.DIRECTION), 0.0);
    vec3 F0 = vec3(0.04);
    vec3 F = F0 + (1.0 - F0) * pow(1.0 - NoV, 5.0);
    vec3 kS = F;
    vec3 kD = 1.0 - kS;
    kD *= 1.0 - getMetallic();
    vec3 diffuse = irradiance * getAlbedo() * kD * getAmbientOcclusion();
    vec3 specular = radiance * (F * brdf.x + brdf.y);
    return diffuse + specular;
}

vec3 getSpecularCookTorrance(Light light) {
    vec3 N = getNormal();
    vec3 V = CAMERA.DIRECTION;
    vec3 L = light.DIRECTION;
    vec3 H = normalize(V + L);
    float NoH = max(dot(N, H), 0.0);
    float NoV = max(dot(N, V), 0.0);
    float NoL = max(dot(N, L), 0.0);
    float LoH = max(dot(L, H), 0.0);
    float VoH = max(dot(V, H), 0.0);
    float roughness = getRoughness();
    float metallic = getMetallic();
    vec3 F0 = vec3(0.04);
    vec3 F = F0 + (1.0 - F0) * pow(1.0 - VoH, 5.0);
    float G = NoL * NoV / (NoL * (1.0 - roughness) + roughness);
    float D = (roughness * roughness) / (PI * pow(NoH * NoH * (roughness * roughness - 1.0) + 1.0, 2.0));
    vec3 specular = F * G * D / (4.0 * NoL * NoV);
    return specular;
}

vec3 getLight() {
    vec3 light = vec3(0.0);
    for (int i = 0; i < 8; i++) {
        if (LIGHTS[i].TYPE == 0) {
            light += LIGHTS[i].COLOR * getDiffuse();
        } else if (LIGHTS[i].TYPE == 1) {
            light += LIGHTS[i].COLOR * getSpecularCookTorrance(LIGHTS[i]);
        }
    }
    return light;
}

vec3 getEnvRadiance() {
    vec3 N = getNormal();
    vec3 R = reflect(-CAMERA.DIRECTION, N);
    return texture(ENVIRONMENT_MAP, R).rgb;
}

void main() {
    vec3 color = getLight();
    color += getEnvRadiance() * getSpecular();
    color += getEmissive();
    color += getAmbient();
    COLOR = color;
}