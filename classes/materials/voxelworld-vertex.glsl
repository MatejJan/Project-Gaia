uniform float totalGameTime;
uniform int blockTypesCount;
uniform sampler2D tileset;
uniform vec2 tilesetSize;
uniform bool visualizeTemperature;
uniform bool visualizeHumidity;

varying vec3 vMaterialDiffuse;
varying vec3 vMaterialEmmisive;
varying float vMaterialOpacity;

varying vec3 vLightFront;
varying vec3 vIndirectFront;
varying vec3 vIndirectFactor;
varying vec2 vUv;

#include <common>
#include <lights_pars_begin>
#include <shadowmap_pars_vertex>
#include <voxelworld_pars_vertex>

void main() {
  bool textured = false;

  bool discardInvisible = !(visualizeTemperature || visualizeHumidity);

  #include <voxelworld_discardinvisible_vertex>

  #include <beginnormal_vertex>
  #include <defaultnormal_vertex>

  #include <begin_vertex>

  // Make empty blocks smaller.
  if (blockMaterial == 0) {
    vec3 blockCenter = blockCoordinates + vec3(0.5, 0.5, -0.5);
    vec3 relativePosition = position - blockCenter;
    transformed = blockCenter + relativePosition * 0.1;
  }

  #include <project_vertex>
  #include <worldpos_vertex>
  #include <lights_lambert_vertex>
  #include <shadowmap_vertex>

  if (textured) {
    vMaterialDiffuse = vec3(1.0);
  } else {
    int paletteRow = blockTypesCount + 1;
    vec2 blockMaterialColorCoordinates = vec2((float(blockMaterial) + 0.5) / materialDataSize.x, (float(paletteRow) + 0.5) / materialDataSize.y);
    vMaterialDiffuse = texture2D(materialData, blockMaterialColorCoordinates).rgb;
  }

  vMaterialEmmisive = vec3(0.0);
  vMaterialOpacity = 1.0;

  if (visualizeTemperature || visualizeHumidity) {
    vMaterialDiffuse = vec3(0.0);
    if (visualizeTemperature) vMaterialDiffuse.r = blockInformation.g * 255.0 / 4.0;
    if (visualizeHumidity) vMaterialDiffuse.b = blockInformation.b * 255.0 / 4.0;
  }

  // Make empty blocks transparent.
  if (blockMaterial == 0) {
    vMaterialOpacity = max(vMaterialDiffuse.r, vMaterialDiffuse.b);
  }

  // Calculate ambient occlusion.
  float shadowBlockCount = 0.0;
  ivec3 shadowSamplePosition = ivec3(position);

  if (getBlockMaterialForPosition(shadowSamplePosition) > 0) {shadowBlockCount++;}
  shadowSamplePosition.x--;
  if (getBlockMaterialForPosition(shadowSamplePosition) > 0) {shadowBlockCount++;}
  shadowSamplePosition.z++;
  if (getBlockMaterialForPosition(shadowSamplePosition) > 0) {shadowBlockCount++;}
  shadowSamplePosition.x++;
  if (getBlockMaterialForPosition(shadowSamplePosition) > 0) {shadowBlockCount++;}

  vIndirectFactor = vec3(1.0 - shadowBlockCount / 4.0);

  if (textured) {
    // Calculate texture coordinates.
    if (normal.x != 0.0) {
      vUv = vec2(position.z - blockCoordinates.z + 1.0, position.y - blockCoordinates.y);
    } else if (normal.y != 0.0) {
      vUv = vec2(position.x - blockCoordinates.x, -position.z + blockCoordinates.z);
    } else {
      vUv = vec2(position.x - blockCoordinates.x, position.y - blockCoordinates.y);
    }

    float tilesCount = tilesetSize.x / 32.0;
    vUv.x = (float(blockMaterial) + vUv.x * 0.98 + 0.01) / tilesCount;
  }
}
