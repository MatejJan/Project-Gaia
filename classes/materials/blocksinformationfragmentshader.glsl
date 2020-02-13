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

  if (vegetationMaterial > 0 && blockType != 3) {
    // Add vegetation.
    blockType = 3;
    blockMaterial = vegetationMaterial;

  } else if (vegetationMaterial == 0 && blockType == 3) {
    // Vegetation needs to be removed.
    blockType = 0;
  }

  ivec3 neigborPositions[6];
  neigborPositions[0] = blockPosition + ivec3(1, 0, 0);
  neigborPositions[1] = blockPosition + ivec3(-1, 0.0, 0.0);
  neigborPositions[2] = blockPosition + ivec3(0, 1, 0);
  neigborPositions[3] = blockPosition + ivec3(0, -1, 0);
  neigborPositions[4] = blockPosition + ivec3(0, 0, 1);
  neigborPositions[5] = blockPosition + ivec3(0, 0, -1);

  bool neigborValid[6];
  ivec4 neighborProperties[6];

  for (int i=0; i<6; i++) {
    if (isValidPosition(neigborPositions[i])) {
      neigborValid[i] = true;
      neighborProperties[i] = ivec4(texture2D(blocksInformation, getTextureCoordinatesForPosition(neigborPositions[i])) * 255.0);
    }
  }

  bool airUp = neighborProperties[2].r == 0;
  bool airDown = neighborProperties[3].r == 0;

  int temperatureUp = neighborProperties[2].g;
  int temperatureDown = neighborProperties[3].g;

  int humidityUp = neighborProperties[2].b;
  int humidityDown = neighborProperties[3].b;

  if (blockType == 0) {
    // Move warmer air up.
    int temperatureFlowToTop = positive(temperature - temperatureUp);
    int temperatureFlowFromBottom = positive(temperatureDown - temperature);

    temperature += -temperatureFlowToTop + temperatureFlowFromBottom;

    // Move humidity up with air, except for rain.
    if (humidity < 4) {
      if (airUp && temperatureFlowToTop > humidity && blockPosition.y < int(worldSize.y - 1.0)) {
        humidity--;
      }

      if (airDown && humidityDown > 0 && temperatureFlowFromBottom > humidityDown) {
        humidity++;
      }
    }

    // Apply air heating.
    int temperatureFlow = 0;

    for (int i=0; i<6; i++) {
      if (!neigborValid[i]) continue;

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
  } else {
    // Apply thermal conduction to non-air blocks.
    int temperatureFlow = 0;

    for (int i=0; i<6; i++) {
      if (!neigborValid[i]) continue;

      // Conduction only applies to non-air blocks.
      if (neighborProperties[i].r == 0) continue;

      int neighborTemperature = neighborProperties[i].g;
      int temperatureDifference = neighborTemperature - temperature;
      if (temperatureDifference > 1) temperatureFlow++;
      if (temperatureDifference < -1) temperatureFlow--;
    }

    if (temperatureFlow > 0) {
      temperature++;
    } else if (temperatureFlow < 0) {
      temperature--;
    }
  }

  // Simulate evaporation.
  if (blockType == 0) {
    if (humidity== 0) {
      // Add humidity from solid blocks.
      for (int i=0; i<6; i++) {
        if (!neigborValid[i]) continue;

        // evaporation only applies to non-air blocks.
        if (neighborProperties[i].r == 0) continue;

        int neighborHumidity = neighborProperties[i].b;
        int neighborTemperature = neighborProperties[i].g;

        if (neighborHumidity > 0 && random(10 + i) < 0.05 * float(neighborTemperature)) {
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
    if (humidity == 3 && random(1) < 0.0001) {
      humidity = 4;
    }
  } else {
    // Remove humidity due to evaporation.
    if (humidity > 0 && random(2) < 0.0005 * float(temperature)) {
      humidity--;
    }

    // Accept rain.
    if (airUp && humidityUp == 4) {
      humidity++;
    }
  }

  // Calculate block type.

  // For air, earth, and water, calculate block material from the properties.
  if (blockType < 2) {
    float materialDataIndex = float(temperature + humidity * 5);
    blockMaterial = int(texture2D(materialData, vec2((materialDataIndex + 0.5) / materialDataSize.x, (float(blockType) + 0.5) / materialDataSize.y)).r * 255.0);
  }

  gl_FragColor = vec4(blockType, clampProperty(temperature), clampProperty(humidity), blockMaterial) / 255.0;
}
