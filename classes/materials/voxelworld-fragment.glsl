
varying vec3 vMaterialDiffuse;
varying vec3 vMaterialEmmisive;

varying vec3 vLightFront;
varying vec3 vIndirectFront;
varying vec3 vIndirectFactor;

#include <common>
#include <packing>
#include <bsdfs>
#include <lights_pars_begin>
#include <shadowmap_pars_fragment>
#include <shadowmask_pars_fragment>

void main() {
  vec4 diffuseColor = vec4(vMaterialDiffuse, 1);

  ReflectedLight reflectedLight = ReflectedLight(vec3(0.0), vec3(0.0), vec3(0.0), vec3(0.0));
  vec3 totalEmissiveRadiance = vMaterialEmmisive;

  reflectedLight.indirectDiffuse = getAmbientLightIrradiance(ambientLightColor);
  reflectedLight.indirectDiffuse += vIndirectFront;
  reflectedLight.indirectDiffuse *= BRDF_Diffuse_Lambert(diffuseColor.rgb);
  reflectedLight.indirectDiffuse *= vIndirectFactor;

  reflectedLight.directDiffuse = vLightFront;
  reflectedLight.directDiffuse *= BRDF_Diffuse_Lambert(diffuseColor.rgb) * getShadowMask();

  vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
  gl_FragColor = vec4(outgoingLight, diffuseColor.a);

  #include <tonemapping_fragment>
  #include <encodings_fragment>
}
