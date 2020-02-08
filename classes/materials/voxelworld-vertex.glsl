uniform float totalGameTime;
uniform int blockTypesCount;

uniform sampler2D materialData;
uniform vec2 materialDataSize;

varying vec3 vMaterialDiffuse;
varying vec3 vMaterialEmmisive;
varying vec3 vLightFront;
varying vec3 vIndirectFront;

#include <common>
#include <lights_pars_begin>
#include <shadowmap_pars_vertex>
#include <voxelworld_pars_vertex>

void main() {
  #include <voxelworld_discardinvisible_vertex>

  #include <beginnormal_vertex>
  #include <defaultnormal_vertex>

  #include <begin_vertex>
  #include <project_vertex>
  #include <worldpos_vertex>
  #include <lights_lambert_vertex>
  #include <shadowmap_vertex>

  // Fetch material color.
  int paletteRow = blockTypesCount + 1;
  vec2 blockMaterialColorCoordinates = vec2((float(blockMaterial) + 0.5) / materialDataSize.x, (float(paletteRow) + 0.5) / materialDataSize.y);
  vMaterialDiffuse = texture2D(materialData, blockMaterialColorCoordinates).rgb;
  vMaterialEmmisive = vec3(0.0);
}
