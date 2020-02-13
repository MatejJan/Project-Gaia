uniform sampler2D tileset;
uniform vec2 tilesetSize;

varying vec3 vMaterialDiffuse;
varying vec3 vMaterialEmmisive;
varying float vMaterialOpacity;

varying vec3 vLightFront;
varying vec3 vIndirectFront;
varying vec3 vIndirectFactor;
varying vec2 vUv;

#include <common>
#include <packing>
#include <bsdfs>
#include <lights_pars_begin>
#include <shadowmap_pars_fragment>
#include <shadowmask_pars_fragment>

void main() {
  if (vMaterialOpacity == 0.0) {
    discard;
  }

  ReflectedLight reflectedLight = ReflectedLight(vec3(0.0), vec3(0.0), vec3(0.0), vec3(0.0));
  vec3 totalEmissiveRadiance = vMaterialEmmisive;

  vec3 materialDiffuse = vMaterialDiffuse;
  if (vUv.x != 0.0) materialDiffuse = texture2D(tileset, vUv).rgb;

  reflectedLight.indirectDiffuse = getAmbientLightIrradiance(ambientLightColor);
  reflectedLight.indirectDiffuse += vIndirectFront;
  reflectedLight.indirectDiffuse *= BRDF_Diffuse_Lambert(materialDiffuse);
  reflectedLight.indirectDiffuse *= vIndirectFactor;

  reflectedLight.directDiffuse = vLightFront;
  reflectedLight.directDiffuse *= BRDF_Diffuse_Lambert(materialDiffuse) * getShadowMask();

  vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
  gl_FragColor = vec4(outgoingLight, vMaterialOpacity);

  #include <tonemapping_fragment>
  #include <encodings_fragment>
}
