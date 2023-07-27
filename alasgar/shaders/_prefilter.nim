$SHADER_PROFILE$
precision mediump float;

#define MATH_PI 3.1415926535897932384626433832795
//#define MATH_INV_PI (1.0 / MATH_PI)

uniform samplerCube u_cubemap;

// enum
const int LAMBERTIAN = 0;
const int cGGX = 1;
const int CHARLIE = 2;

uniform float u_roughness;
uniform int u_sample_count;
uniform int u_width;
uniform float u_lod_bias;
uniform int u_distribution; // enum
uniform int u_current_face;
uniform int u_is_generating_lut;

in vec2 UV;


out vec4 o_color;

//layout(location = 6) out vec3 outLUT;


proc uvToXYZ(FACE: int, UV: Vec2): Vec3 =
    if FACE == 0:
        result = vec3(1.0, UV.y, -UV.x)
    elif FACE == 1:
        result = vec3(-1.0, UV.y, UV.x)
    elif FACE == 2:
        result = vec3(UV.x, -1.0, UV.y)
    elif FACE == 3:
        result = vec3(UV.x, 1.0, -UV.y)
    elif FACE == 4:
        result = vec3(UV.x, UV.y, 1.0)
    else:
        result = vec3(-UV.x, UV.y, -1.0)


proc dirToUV(dir: Vec3): Vec2 =
    vec2(
        0.5 + 0.5 * atan(dir.z, dir.x) / PI,
        1.0 - acos(dir.y) / PI
    )

# Hammersley Points on the Hemisphere
# CC BY 3.0 (Holger Dammertz)
# http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html
proc radicalInverse_VdC(bits: uint32): float =
    results = (bits << 16.uint32) | (bits >> 16.uint32)
    results = ((results and 0x55555555.uint32) shl 1.uint32) or ((results & 0xAAAAAAAA.uint32) >> 1.uint32)
    results = ((results and 0x33333333.uint32) shl 2.uint32) or ((results & 0xCCCCCCCC.uint32) >> 2.uint32)
    results = ((results and 0x0F0F0F0F.uint32) shl 4.uint32) or ((results & 0xF0F0F0F0.uint32) >> 4.uint32)
    results = ((results and 0x00FF00FF.uint32) shl 8.uint32) or ((results & 0xFF00FF00.uint32) >> 8.uint32)
    return bits.floats * 2.3283064365386963e-10


# hammersley2d describes a sequence of points in the 2d unit square [0,1)^2
# that can be used for quasi Monte Carlo integration
proc hammersley2d(i, N: int): Vec2 =  vec2(float(i)/float(N), radicalInverse_VdC(i.uint32))


# Hemisphere Sample
# TBN generates a tangent bitangent normal coordinate frame from the normal
# (the normal must be normalized)
proc generateTBN(normal: Vec3): Mat3 =
    var 
        bitangent = vec3(0.0, 1.0, 0.0)
        NoUP = dot(normal, vec3(0.0, 1.0, 0.0))

    if 1.0 - abs(NoUP) <= EPLSILON:
        # Sampling +Y or -Y, so we need a more robust bitangent.
        if NdotUp > 0.0:
            bitangent = vec3(0.0, 0.0, 1.0)
        else:
            bitangent = vec3(0.0, 0.0, -1.0)

    var tangent = normalize(cross(bitangent, normal))
    bitangent = cross(normal, tangent)

    result = mat3(tangent, bitangent, normal)


type 
    MicrofacetDistributionSample = object
        pdf: float
        cosTheta: float
        sinTheta: float
        phi: float

proc D_GGX(float NdotH, float roughness): float =
    let 
        a = NdotH * roughness;
        k = roughness / (1.0 - NdotH * NdotH + a * a)
    result = k * k * (1.0 / PI)

# NDF

proc D_Ashikhmin(NoH, alpha: float): float =
    # Ashikhmin 2007, "Distribution-based BRDFs"
    let 
        a2 = alpha * alpha
        cos2h = NoH * NoH
        sin2h = 1.0 - cos2h
        sin4h = sin2h * sin2h
        cot2 = -cos2h / (a2 * sin2h)
    result = 1.0 / (PI * (4.0 * a2 + 1.0) * sin4h) * (4.0 * exp(cot2) + sin4h)

proc D_Charlie(sheenRoughness, NoH: float): float =
    let 
        invR = 1.0 / clamp(sheenRoughness, EPLSILON, 1.0)
        cos2h = NoH * NoH
        sin2h = 1.0 - cos2h
    result = (2.0 + invR) * pow(sin2h, invR * 0.5) / (2.0 * PI)

# GGX microfacet distribution
# https://www.cs.cornell.edu/~srm/publications/EGSR07-btdf.html
# This implementation is based on https://bruop.github.io/ibl/,
#  https://www.tobias-franke.eu/log/2014/03/30/notes_on_importance_sampling.html
# and https://developer.nvidia.com/gpugems/GPUGems3/gpugems3_ch20.html
proc GGX(xi: Vec2, roughness: float): MicrofacetDistributionSample =
    # evaluate sampling equations
    let 
        alpha = roughness * roughness
    result.cosTheta = saturate(sqrt((1.0 - xi.y) / (1.0 + (alpha * alpha - 1.0) * xi.y)))
    result.sinTheta = sqrt(1.0 - result.cosTheta * result.cosTheta)
    result.phi = 2.0 * MATH_PI * xi.x;

    # evaluate GGX pdf (for half vector)
    result.pdf = D_GGX(result.cosTheta, alpha);

    # Apply the Jacobian to obtain a pdf that is parameterized by l
    # see https://bruop.github.io/ibl/
    # Typically you'd have the following:
    # float pdf = D_GGX(NoH, roughness) * NoH / (4.0 * VoH);
    # but since V = N => VoH == NoH
    result.pdf = result.pdf * 0.25


proc Charlie(xi: vec2, alpha: float): MicrofacetDistributionSample =
    result.sinTheta = pow(xi.y, alpha / (2.0*alpha + 1.0))
    result.cosTheta = sqrt(1.0 - charlie.sinTheta * charlie.sinTheta)
    result.phi = 2.0 * PI * xi.x

    # evaluate Charlie pdf (for half vector)
    result.pdf = D_Charlie(alpha, charlie.cosTheta)

    # Apply the Jacobian to obtain a pdf that is parameterized by l
    result.pdf /= 4.0

proc Lambertian(xi: vec2, roughness: float): MicrofacetDistributionSample =
    # Cosine weighted hemisphere sampling
    # http://www.pbr-book.org/3ed-2018/Monte_Carlo_Integration/2D_Sampling_with_Multidimensional_Transformations.html#Cosine-WeightedHemisphereSampling
    result.cosTheta = sqrt(1.0 - xi.y)
    # equivalent to `sqrt(1.0 - cosTheta*cosTheta)`;
    result.sinTheta = sqrt(xi.y) 
    result.phi = 2.0 * PI * xi.x

    # evaluation for solid angle, therefore drop the sinTheta
    result.pdf = lambertian.cosTheta / PI 


# getImportanceSample returns an importance sample direction with pdf in the .w component
vec4 getImportanceSample(int sampleIndex, vec3 N, float roughness)
{
    // generate a quasi monte carlo point in the unit square [0.1)^2
    vec2 xi = hammersley2d(sampleIndex, u_sample_count);

    MicrofacetDistributionSample importanceSample;

    // generate the points on the hemisphere with a fitting mapping for
    // the distribution (e.g. lambertian uses a cosine importance)
    if(u_distribution == LAMBERTIAN)
    {
        importanceSample = Lambertian(xi, roughness);
    }
    else if(u_distribution == cGGX)
    {
        // Trowbridge-Reitz / GGX microfacet model (Walter et al)
        // https://www.cs.cornell.edu/~srm/publications/EGSR07-btdf.html
        importanceSample = GGX(xi, roughness);
    }
    else if(u_distribution == CHARLIE)
    {
        importanceSample = Charlie(xi, roughness);
    }

    // transform the hemisphere sample to the normal coordinate frame
    // i.e. rotate the hemisphere to the normal direction
    vec3 localSpaceDirection = normalize(vec3(
        importanceSample.sinTheta * cos(importanceSample.phi), 
        importanceSample.sinTheta * sin(importanceSample.phi), 
        importanceSample.cosTheta
    ));
    mat3 TBN = generateTBN(N);
    vec3 direction = TBN * localSpaceDirection;

    return vec4(direction, importanceSample.pdf);
}

// Mipmap Filtered Samples (GPU Gems 3, 20.4)
// https://developer.nvidia.com/gpugems/gpugems3/part-iii-rendering/chapter-20-gpu-based-importance-sampling
// https://cgg.mff.cuni.cz/~jaroslav/papers/2007-sketch-fis/Final_sap_0073.pdf
float computeLod(float pdf)
{
    // // Solid angle of current sample -- bigger for less likely samples
    // float omegaS = 1.0 / (float(u_sample_count) * pdf);
    // // Solid angle of texel
    // // note: the factor of 4.0 * MATH_PI 
    // float omegaP = 4.0 * MATH_PI / (6.0 * float(u_width) * float(u_width));
    // // Mip level is determined by the ratio of our sample's solid angle to a texel's solid angle 
    // // note that 0.5 * log2 is equivalent to log4
    // float lod = 0.5 * log2(omegaS / omegaP);

    // babylon introduces a factor of K (=4) to the solid angle ratio
    // this helps to avoid undersampling the environment map
    // this does not appear in the original formulation by Jaroslav Krivanek and Mark Colbert
    // log4(4) == 1
    // lod += 1.0;

    // We achieved good results by using the original formulation from Krivanek & Colbert adapted to cubemaps

    // https://cgg.mff.cuni.cz/~jaroslav/papers/2007-sketch-fis/Final_sap_0073.pdf
    float lod = 0.5 * log2( 6.0 * float(u_width) * float(u_width) / (float(u_sample_count) * pdf));


    return lod;
}

vec3 filterColor(vec3 N)
{
    //return  textureLod(u_cubemap, N, 3.0).rgb;
    vec3 color = vec3(0.f);
    float weight = 0.0f;

    for(int i = 0; i < u_sample_count; ++i)
    {
        vec4 importanceSample = getImportanceSample(i, N, u_roughness);

        vec3 H = vec3(importanceSample.xyz);
        float pdf = importanceSample.w;

        // mipmap filtered samples (GPU Gems 3, 20.4)
        float lod = computeLod(pdf);

        // apply the bias to the lod
        lod += u_lod_bias;

        if(u_distribution == LAMBERTIAN)
        {
            // sample lambertian at a lower resolution to avoid fireflies
            vec3 lambertian = textureLod(u_cubemap, H, lod).rgb;

            //// the below operations cancel each other out
            // lambertian *= NdotH; // lamberts law
            // lambertian /= pdf; // invert bias from importance sampling
            // lambertian /= MATH_PI; // convert irradiance to radiance https://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/

            color += lambertian;
        }
        else if(u_distribution == cGGX || u_distribution == CHARLIE)
        {
            // Note: reflect takes incident vector.
            vec3 V = N;
            vec3 L = normalize(reflect(-V, H));
            float NdotL = dot(N, L);

            if (NdotL > 0.0)
            {
                if(u_roughness == 0.0)
                {
                    // without this the roughness=0 lod is too high
                    lod = u_lod_bias;
                }
                vec3 sampleColor = textureLod(u_cubemap, L, lod).rgb;
                color += sampleColor * NdotL;
                weight += NdotL;
            }
        }
    }

    if(weight != 0.0f)
    {
        color /= weight;
    }
    else
    {
        color /= float(u_sample_count);
    }

    return color.rgb ;
}

// From the filament docs. Geometric Shadowing function
// https://google.github.io/filament/Filament.html#toc4.4.2
float V_SmithGGXCorrelated(float NoV, float NoL, float roughness) {
    float a2 = pow(roughness, 4.0);
    float GGXV = NoL * sqrt(NoV * NoV * (1.0 - a2) + a2);
    float GGXL = NoV * sqrt(NoL * NoL * (1.0 - a2) + a2);
    return 0.5 / (GGXV + GGXL);
}

// https://github.com/google/filament/blob/master/shaders/src/brdf.fs#L136
float V_Ashikhmin(float NdotL, float NdotV)
{
    return clamp(1.0 / (4.0 * (NdotL + NdotV - NdotL * NdotV)), 0.0, 1.0);
}

// Compute LUT for GGX distribution.
// See https://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf
vec3 LUT(float NdotV, float roughness)
{
    // Compute spherical view vector: (sin(phi), 0, cos(phi))
    vec3 V = vec3(sqrt(1.0 - NdotV * NdotV), 0.0, NdotV);

    // The macro surface normal just points up.
    vec3 N = vec3(0.0, 0.0, 1.0);

    // To make the LUT independant from the material's F0, which is part of the Fresnel term
    // when substituted by Schlick's approximation, we factor it out of the integral,
    // yielding to the form: F0 * I1 + I2
    // I1 and I2 are slighlty different in the Fresnel term, but both only depend on
    // NoL and roughness, so they are both numerically integrated and written into two channels.
    float A = 0.0;
    float B = 0.0;
    float C = 0.0;

    for(int i = 0; i < u_sample_count; ++i)
    {
        // Importance sampling, depending on the distribution.
        vec4 importanceSample = getImportanceSample(i, N, roughness);
        vec3 H = importanceSample.xyz;
        // float pdf = importanceSample.w;
        vec3 L = normalize(reflect(-V, H));

        float NdotL = saturate(L.z);
        float NdotH = saturate(H.z);
        float VdotH = saturate(dot(V, H));
        if (NdotL > 0.0)
        {
            if (u_distribution == cGGX)
            {
                // LUT for GGX distribution.

                // Taken from: https://bruop.github.io/ibl
                // Shadertoy: https://www.shadertoy.com/view/3lXXDB
                // Terms besides V are from the GGX PDF we're dividing by.
                float V_pdf = V_SmithGGXCorrelated(NdotV, NdotL, roughness) * VdotH * NdotL / NdotH;
                float Fc = pow(1.0 - VdotH, 5.0);
                A += (1.0 - Fc) * V_pdf;
                B += Fc * V_pdf;
                C += 0.0;
            }

            if (u_distribution == CHARLIE)
            {
                // LUT for Charlie distribution.
                float sheenDistribution = D_Charlie(roughness, NdotH);
                float sheenVisibility = V_Ashikhmin(NdotL, NdotV);

                A += 0.0;
                B += 0.0;
                C += sheenVisibility * sheenDistribution * NdotL * VdotH;
            }
        }
    }

    // The PDF is simply pdf(v, h) -> NDF * <nh>.
    // To parametrize the PDF over l, use the Jacobian transform, yielding to: pdf(v, l) -> NDF * <nh> / 4<vh>
    // Since the BRDF divide through the PDF to be normalized, the 4 can be pulled out of the integral.
    return vec3(4.0 * A, 4.0 * B, 4.0 * 2.0 * MATH_PI * C) / float(u_sample_count);
}



// entry point
void main()
{
    vec3 color = vec3(0);

    if(u_is_generating_lut == 0)
    {
        vec2 newUV = UV ;

        newUV = newUV*2.0-1.0;

        vec3 scan = uvToXYZ(u_current_face, newUV);

        vec3 direction = normalize(scan);
        direction.y = -direction.y;
    
        color = filterColor(direction);
    }
    else
    {
        color = LUT(UV.x, UV.y);
    }
    
    o_color = vec4(color, 1.0);
}