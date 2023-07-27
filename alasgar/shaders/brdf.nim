import types
import common

proc getIrradianceSphericalHarmonics*(N: Vec3): Vec3 = 
  # Irradiance from "Ditch River" IBL
  # (http://www.hdrlabs.com/sibl/archive.html)
  result = max(
      vec3(0.754554516862612, 0.748542953903366, 0.790921515418539) +
          vec3(-0.083856548007422, 0.092533500963210, 0.322764661032516) *
              (N.y) +
          vec3(0.308152705331738, 0.366796330467391, 0.466698181299906) *
              (N.z) +
          vec3(-0.188884931542396, -0.277402551592231, -0.377844212327557) *
              (N.x),
      0.0)

proc calculateBRDF(FRAGMENT: Fragment, NoH: float, LoH: float): float =
    let 
        
        d: float = NoH * NoH * FRAGMENT.ROUGHNESS2_MINUS_ONE + 1.00001
        LoH2: float = LoH * LoH
        
    result = FRAGMENT.ALPHA / ((d * d) * max(0.1, LoH2) * FRAGMENT.NORMALIZED_ROUGHNESS)

proc getBRDF*(FRAGMENT: Fragment, LIGHT: Light, NoL, NoH, LoH: float): Vec3 =
    let
        radiance: Vec3 = NoL * getIrradianceSphericalHarmonics(FRAGMENT.N)
        brdf: float = calculateBRDF(FRAGMENT, NoH, LoH)
    result = (brdf * FRAGMENT.SPECULAR + FRAGMENT.ALBEDO) * radiance

# Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
proc fSchlick*(F0: Vec3, VoH: float): Vec3 = F0 + (vec3(1.0) - F0) * pow5(1.0 - VoH)

proc getPhong*(FRAGMENT: FRAGMENT, LIGHT: Light, L, H: Vec3, NoL, NoH, VoH: float): Vec3 =
    let 
        fresnelTerm = fSchlick(vec3(0.04), VoH)
        diffuseTerm = (1.0 - fresnelTerm) * FRAGMENT.ALBEDO / PI
        visibilityTerm = 0.25
        phongBlinn = pow(NoH, FRAGMENT.SHININESS)
        blinnNormalization = (FRAGMENT.SHININESS + 8.0) / (8.0 * PI)
        normalDistribution = phongBlinn * blinnNormalization
        specularTerm = fresnelTerm * visibilityTerm * normalDistribution * FRAGMENT.SPECULAR
    result = (diffuseTerm + specularTerm) * LIGHT.COLOR

proc blinnPhong*(FRAGMENT: Fragment, LIGHT: Light, NoL, NoH: float): Vec3 =
    let
        specular = if NoL > 0.0: pow(NoH, FRAGMENT.SHININESS) else: 0.0
    result = specular * FRAGMENT.SPECULAR

proc orenNayarDiffuse*(NoL, NoV, LoV, ALPHA, ALBEDO: float): float =
    let 
        s = LoV - NoL * NoV
        t = mix(1.0, max(NoL, NoV), step(0.0, s))
        A = 1.0 + ALPHA * (ALBEDO / (ALPHA + 0.13) + 0.5 / (ALPHA + 0.33))
        B = 0.45 * ALPHA / (ALPHA + 0.09)
    result = ALBEDO * max(0.0, NoL) * (A + B * s / t) / PI


#[
float3 half_vector = normalize( eye_dir + light_dir );
float n_dot_l = saturate( dot( normal, light_dir ) );
float n_dot_h = saturate(dot( normal, half_vector );
float h_dot_l = saturate(dot( half_vector, light_dir ));
// Amount of reflected energy based on angle
// usually is [f0 + (1-f0)*pow( 1 - l_dot_h, 5 )]
// f0 is another name for specular colour
// should be very low (< 0.17) and gray for dielectric
// should be high (> 0.7) for metals. 1.0 for crome.
float3 fresnel_term = FSlick( f0, l_dot_h );
// Reflected energy is not diffused, so we remove the fresnel
float3 diffuse_term = (1 - fresnel)*albedo/pi;
// implicit visibility term, can be substitute with SmithGGX for better results.
float visibility_term = 0.25;
float phong_blinn = pow( n_dot_h, specular_power );
// Check http://www.farbrausch.de/~fg/stuff/phong.pdf for reference
float blinn_normalization = ( specular_power + 8.0 ) / (8.0*pi);
float normal_distribution = phong_blinn * blinn_normalization;
float3 specular_term = fresnel_term * visibility_term * normal_distribution;
return light_intensity * (diffuse_term + specular_term) * n_dot_l;    
]#