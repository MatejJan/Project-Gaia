uniform int blockTypesCount;
uniform sampler2D tileset;
uniform vec2 tilesetSize;
uniform bool visualizeTemperature;
uniform bool visualizeHumidity;

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
#include <lights_pars_begin>
#include <shadowmap_pars_vertex>
#include <voxelworld_pars_vertex>

#define computeWaterNormal

void main() {
  bool textured = false;

  bool discardInvisible = !(visualizeTemperature || visualizeHumidity);

  #include <voxelworld_blockinformation>
  #include <voxelworld_discardinvisible_vertex>

  #include <beginnormal_vertex>
  #include <defaultnormal_vertex>
  #include <begin_vertex>

  // Make empty blocks smaller.
  if (blockMaterial == materialsEmpty) {
    vec3 blockCenter = blockCoordinates + vec3(0.5, 0.5, -0.5);
    vec3 relativePosition = position - blockCenter;
    float size = 0.1;
    if (visualizeTemperature || visualizeHumidity) {
      size = 0.0;
      if (visualizeTemperature) size = float(temperature) / 20.0;
      if (visualizeHumidity) size = max(size, float(humidity) / 10.0);
    }
    transformed = blockCenter + relativePosition * size;
  }

  #include <voxelworld_waterwaves_vertex>

  vNormal = normalize(transformedNormal);

  #include <project_vertex>
  #include <worldpos_vertex>
  #include <lights_lambert_vertex>
  #include <shadowmap_vertex>
  vViewPosition = -mvPosition.xyz;
  vMainLightDirection = directionalLights[0].direction;

  if (textured) {
    vMaterialDiffuse = vec3(1.0);
  } else {
    int paletteRow = blockTypesCount + 1;
    vec2 blockMaterialColorCoordinates = vec2((float(blockMaterial) + 0.5) / materialDataSize.x, (float(paletteRow) + 0.5) / materialDataSize.y);
    vMaterialDiffuse = texture2D(materialData, blockMaterialColorCoordinates).rgb;
  }

  vMaterialOpacity = 1.0;
  vMaterialReflectivity = 0.0;

  if (visualizeTemperature || visualizeHumidity) {
    vMaterialDiffuse = vec3(0.0);

    if (visualizeTemperature) {
      if (blockMaterial == materialsEmpty) {
        vMaterialDiffuse.r = temperature > 0 ? 255.0: 0.0;
      } else {
        vMaterialDiffuse.r = float(temperature) / 4.0;
      }
    }

    if (visualizeHumidity) {
      if (blockMaterial == materialsEmpty) {
        vMaterialDiffuse.b = humidity > 0 ? 255.0: 0.0;
      } else {
        vMaterialDiffuse.b = float(humidity) / 4.0;
      }
    }
  }

  // Make empty blocks transparent.
  if (blockMaterial == materialsEmpty) {
    vMaterialOpacity = float(max(temperature, humidity)) / 4.0;
  }

  // Make water semi-transparent and shiny.
  if (blockMaterial == materialsWater || blockMaterial == materialsRain) {
    vMaterialOpacity = blockMaterial == materialsWater ? 0.3 : 0.7;
    vMaterialReflectivity = 0.5;
  }

  // Calculate ambient occlusion.
  ivec3 shadowSamplePosition[4];
  shadowSamplePosition[0] = ivec3(position);
  shadowSamplePosition[1] = ivec3(position + vec3(-1, 0, 0));
  shadowSamplePosition[2] = ivec3(position + vec3(-1, 0, 1));
  shadowSamplePosition[3] = ivec3(position + vec3(0, 0, 1));

  float shadowBlockCount = 0.0;
  for (int i = 0; i < 4; i++) {
    int shadowSampleBlock = getBlockMaterialForPosition(shadowSamplePosition[i]);
    if (shadowSampleBlock != materialsEmpty) {
      if (shadowSampleBlock == materialsWater) {
        // We're in water so shadows grow twice as slow. Look one more up if there's something there as well.
        shadowSampleBlock = getBlockMaterialForPosition(shadowSamplePosition[i] + ivec3(0, 1, 0));
        if (shadowSampleBlock != materialsEmpty) {
          shadowBlockCount++;
        } else {
          shadowBlockCount += 0.5;
        }
      } else {
        shadowBlockCount++;
      }
    }
  }

  float maxShadow = blockMaterial == materialsCloud ? 2.0 : 3.0;
  vIndirectFactor = vec3(1.0 - min(maxShadow, shadowBlockCount) / 4.0);

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
