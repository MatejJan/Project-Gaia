precision highp float;
precision highp int;

#include <voxelworld_common>
#include <computedtexture_common>

int positive(int value) {
  if (value < 0) return 0;
  return value;
}

int clampProperty(int value) {
  if (value < 0) return 0;
  if (value > 4) return 4;
  return value;
}

void main() {
  ivec3 blockPosition = getPositionForTextureCoordinates(vUv);
  if (!isValidPosition(blockPosition)) {
    return;
  }

  vec2 blockCoordinates = getTextureCoordinatesForPosition(blockPosition);
  ivec4 blockProperties = ivec4(texture2D(blocksInformation, blockCoordinates) * 255.0);
  int blockType = blockProperties.r;
  int temperature = blockProperties.g;
  int humidity = blockProperties.b;
  int blockMaterial = blockProperties.a;

  // See if this block needs to be synced with vegetation.
  ivec4 vegetationProperties = ivec4(texture2D(vegetationInformation, blockCoordinates) * 255.0);
  int vegetationMaterial = vegetationProperties.a;

  if (vegetationMaterial > 0 && blockType != blocksVegetation) {
    // Add vegetation.
    blockType = 3;
    blockMaterial = vegetationMaterial;

  } else if (vegetationMaterial == 0 && blockType == blocksVegetation) {
    // Vegetation needs to be removed.
    blockType = 0;
  }

  ivec3 neighborPositions[6];
  neighborPositions[0] = blockPosition + ivec3(1, 0, 0);
  neighborPositions[1] = blockPosition + ivec3(-1, 0.0, 0.0);
  neighborPositions[2] = blockPosition + ivec3(0, 1, 0);
  neighborPositions[3] = blockPosition + ivec3(0, -1, 0);
  neighborPositions[4] = blockPosition + ivec3(0, 0, 1);
  neighborPositions[5] = blockPosition + ivec3(0, 0, -1);

  bool neighborValid[6];
  ivec4 neighborProperties[6];

  for (int i=0; i<6; i++) {
    if (isValidPosition(neighborPositions[i])) {
      neighborValid[i] = true;
      neighborProperties[i] = ivec4(texture2D(blocksInformation, getTextureCoordinatesForPosition(neighborPositions[i])) * 255.0);
    }
  }

  bool airUp = neighborProperties[2].r == 0;
  bool airDown = neighborProperties[3].r == 0;

  int temperatureUp = neighborProperties[2].g;
  int temperatureDown = neighborProperties[3].g;

  int humidityUp = neighborProperties[2].b;
  int humidityDown = neighborProperties[3].b;

  if (blockType == blocksAir) {
    // Move warmer air up.
    int temperatureFlowToTop = positive(temperature - temperatureUp);
    int temperatureFlowFromBottom = positive(temperatureDown - temperature);

    temperature += -temperatureFlowToTop + temperatureFlowFromBottom;

    // Move humidity up with air, except for rain.
    if (humidity < 4) {
      if (airUp && temperatureFlowToTop > 0 && blockPosition.y < int(worldSize.y - 5.0)) {
        humidity--;
      }

      if (airDown && humidityDown > 0 && temperatureFlowFromBottom > 0) {
        humidity++;
      }
    }

    // Apply air heating from ground.
    int temperatureFlow = 0;

    for (int i=0; i<6; i++) {
      if (!neighborValid[i]) continue;

      // heating only applies to non-air blocks.
      if (neighborProperties[i].r == 0) continue;

      int neighborTemperature = neighborProperties[i].g;
      int temperatureDifference = neighborTemperature - temperature;
      if (temperatureDifference > 1) temperatureFlow++;
      if (temperatureDifference < -1) temperatureFlow--;
    }

    if (temperatureFlow > 0) {
      temperature++;
    }
  }

  // Simulate evaporation.
  if (blockType == blocksAir) {
    if (humidity== 0) {
      // Add humidity from solid blocks.
      for (int i=0; i<6; i++) {
        if (!neighborValid[i]) continue;

        int neighborBlockType = neighborProperties[i].r;

        // Evaporation only applies to non-air blocks.
        if (neighborBlockType == blocksAir) continue;

        // Water evaporation is higher.
        float evaporationFactor = neighborBlockType == blocksWater ? 5.0 : 1.0;

        // Evaporation is proportional to temperature.
        int neighborTemperature = neighborProperties[i].g;
        evaporationFactor *= float(neighborTemperature);

        int neighborHumidity = neighborProperties[i].b;

        if (neighborHumidity > 0 && random(10 + i) < 0.01 * evaporationFactor) {
          humidity = 1;
        }
      }
    }

    // Rain falls down.
    if (humidity == 4) {
      humidity = 0;
    }

    if (humidityUp == 4) {
      humidity = 4;
    }

    // Spawn random raindrops.
    if (humidity == 3 && random(1) < 0.001) {
      humidity = 4;
    }
  } else {
    // Remove humidity due to evaporation.
    if (humidity > 0 && random(2) < 0.0001 * float(temperature)) {
      humidity--;
    }

    // Accept rain.
    if (airUp && humidityUp == 4) {
      humidity++;
    }
  }

  // Even out humidity in water.
  if (blockType == blocksWater) {
    int humidityFlow = 0;

    for (int i=0; i<6; i++) {
      if (!neighborValid[i]) continue;
      if (neighborProperties[i].r != blocksWater) continue;

      int neighborHumidity = neighborProperties[i].b;
      int humidityDifference = neighborHumidity - humidity;

      if (humidity == 0) {
        // Always flow to zero humidity.
        if (humidityDifference > 0) humidityFlow++;
      } else {
        // Otherwise only flow when difference is bigger than 1.
        if (humidityDifference > 1) humidityFlow++;
        if (humidityDifference < -1) humidityFlow--;
      }
    }

    if (humidityFlow > 0) {
      humidity++;
    } else if (humidityFlow < 0) {
      humidity--;
    }
  }

  // Calculate block type.

  // For air, earth, and water, calculate block material from the properties.
  if (blockType <= blocksWater) {
    float materialDataIndex = float(temperature + humidity * 5);
    blockMaterial = int(texture2D(materialData, vec2((materialDataIndex + 0.5) / materialDataSize.x, (float(blockType) + 0.5) / materialDataSize.y)).r * 255.0);
  }

  gl_FragColor = vec4(blockType, clampProperty(temperature), clampProperty(humidity), blockMaterial) / 255.0;
}
