uniform sampler2D tileset;
uniform vec2 tilesetSize;

varying vec3 vMaterialDiffuse;
varying float vMaterialOpacity;
varying float vMaterialReflectivity;

varying vec3 vLightFront;
varying vec3 vIndirectFront;
varying vec3 vIndirectFactor;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPosition;
varying vec3 vMainLightDirection;

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

  vec3 materialDiffuse = vMaterialDiffuse;
  if (vUv.x != 0.0) materialDiffuse = texture2D(tileset, vUv).rgb;

  reflectedLight.indirectDiffuse = getAmbientLightIrradiance(ambientLightColor);
  reflectedLight.indirectDiffuse += vIndirectFront;
  reflectedLight.indirectDiffuse *= BRDF_Diffuse_Lambert(materialDiffuse);
  reflectedLight.indirectDiffuse *= vIndirectFactor;

  reflectedLight.directDiffuse = vLightFront;
  reflectedLight.directDiffuse *= BRDF_Diffuse_Lambert(materialDiffuse) * getShadowMask();

  vec3 normal = normalize(vNormal);
  vec3 viewDirection = normalize(vViewPosition);
  float dotNV = saturate(dot(normal, viewDirection));
  float fresnel = exp2((-5.55473 * dotNV - 6.98316) * dotNV);

  vec3 diffuseLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse;

  vec3 light = normalize(vMainLightDirection);
  vec3 eye = -viewDirection;
  float specularIntensity = dot(light, (eye - 2.0 * normal * dot(normal, eye)));
  vec3 specularLight = saturate(specularIntensity) * vLightFront * vMaterialReflectivity;

  vec3 outgoingLight = diffuseLight + specularLight;

  float opacity = mix(vMaterialOpacity, 1.0, fresnel);
  gl_FragColor = vec4(outgoingLight, opacity);

  #include <tonemapping_fragment>
  #include <encodings_fragment>
}
