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

  // Obtain neighbors' properties.
  ivec3 neighborPositions[6];
  neighborPositions[0] = blockPosition + ivec3(0, 0, 1);
  neighborPositions[1] = blockPosition + ivec3(1, 0, 0);
  neighborPositions[2] = blockPosition + ivec3(0, 0, -1);
  neighborPositions[3] = blockPosition + ivec3(-1, 0, 0);
  neighborPositions[4] = blockPosition + ivec3(0, 1, 0);
  neighborPositions[5] = blockPosition + ivec3(0, -1, 0);

  bool neighborValid[6];
  ivec4 neighborProperties[6];

  for (int i=0; i<6; i++) {
    if (isValidPosition(neighborPositions[i])) {
      neighborValid[i] = true;
      neighborProperties[i] = ivec4(texture2D(blocksInformation, getTextureCoordinatesForPosition(neighborPositions[i])) * 255.0);
    }
  }

  bool blockIsAir = blockType == blocksAir;
  bool airUp = neighborProperties[4].r == blocksAir;
  bool airDown = neighborProperties[5].r == blocksAir;

  int humidityUp = neighborProperties[4].b;
  int humidityDown = neighborProperties[5].b;

  float heightRatio = float(blockPosition.y) / worldSize.y;

  // Simulate air flow.
  if (blockIsAir) {
    int windDestination = -1;
    int windSource = -1;

    // Disperse air sideways. Cold to hot on ground, hot to cold above.
    for (int i = 0; i < 4; i++) {
      if (!neighborValid[i] || neighborProperties[i].r != blocksAir) continue;

      int neighborTemperature = neighborProperties[i].g;

      // If there's no temperature difference, no flow is happening in this direction.
      if (neighborTemperature == temperature) continue;

      float chanceForColdToHotDispersion = (1.0 - heightRatio) / 4.0;
      float chanceForHotToColdDispersion = heightRatio / 4.0;

      if (random(55) < chanceForColdToHotDispersion) {
        // Flow from cold to hot.
        if (temperature > neighborTemperature) {
          // We are the hot place, so we should bring in temperature from the cold place.
          windSource = i;
        } else {
          // We are the cold place, so we should give temperature to the hot place.
          windDestination = i;
        }
      }

      if (random(56) < chanceForHotToColdDispersion) {
        // Flow from hot to cold.
        if (temperature > neighborTemperature) {
          // We are the hot place, so we should give the temperature to the cold place.
          windDestination = i;
        } else {
          // We are the cold place, so we should bring in temperature from the hot place.
          windSource = i;
        }
      }
    }

    // If source and destination weren't set, try to flow up.
    if (windSource < 0 && neighborProperties[5].r == blocksAir) windSource = 5;
    if (windDestination < 0 && neighborProperties[4].r == blocksAir) windDestination = 4;

    // Move temperature in the wind direction.

    int windSourceCounter = windSource;
    int windDestinationCounter = windDestination;

    ivec4 propertiesAtDestination;
    ivec4 propertiesAtSource;

    //#pragma unroll_loop
    for (int i = 0; i < 6; i ++) {

      if (windSourceCounter == 0) propertiesAtSource = neighborProperties[i];
      if (windDestinationCounter == 0) propertiesAtDestination = neighborProperties[i];
      windSourceCounter--;
      windDestinationCounter--;

    }

    // Determine flow outwards.
    if (windDestination >= 0) {
      temperature = 0;

      // Move low humidity with wind.
      if (humidity < 3) humidity = 0;
      if (humidity == 3 && windDestination < 4 && random(15) < 0.01) humidity = 0;
    }

    // Determine flow to block.
    if (windSource >= 0) {
      int temperatureAtSource = propertiesAtSource.g;
      temperature += temperatureAtSource;

      // Add humidity from wind direction, except from rain.
      int humidityAtSource = propertiesAtSource.b;
      if (humidity < 3 && (humidityAtSource < 3 || humidityAtSource == 3 && random(9) < 0.5)) {
        humidity = min(2, humidity + humidityAtSource);
      }

      // Clouds can travel horizontally from the source.
      if (humidityAtSource == 3 && windSource < 4 && random(17) < 0.75) humidity = 3;
    }
  }

  // Condense clouds.
  int cloudNeighborsCount = 0;
  int lowHumidityNeighborsCount = 0;

  if (blockIsAir && humidity > 0 && humidity < 4) {
    float condensationChance = max(0.0, 1.0 - abs(float(blockPosition.y) - (worldSize.y - 10.0)) / 3.0);

    for (int i=0; i<6; i++) {
      if (!neighborValid[i] || neighborProperties[i].r != blocksAir) continue;

      int neighborHumidity = neighborProperties[i].b;
      if (neighborHumidity < 3) lowHumidityNeighborsCount++;
      if (neighborHumidity == 3) cloudNeighborsCount++;

      // Two neighboring blocks of equal humidity condense, the higher the more likely.
      if (humidity < 3 && neighborHumidity == humidity && random(22) < 0.01 * condensationChance) {
        humidity++;
      }
    }

    // Apply cloud generation rules
    if (random(56) < 0.02 * float(cloudNeighborsCount * 3)) {
      humidity = 3;
    }

    if (random(57) < 0.0002 * (10.0 - float(cloudNeighborsCount + lowHumidityNeighborsCount))) {
      humidity = 0;
    }

    if (airUp && airDown && humidityUp == 3 && humidityDown == 3) humidity = 3;
  }

  // Decrease humidity above clouds.
  if (blockIsAir && airDown && humidityDown == 3 && humidity < 3) {
    humidity = 0;
  }

  // Decrease temperature in and above clouds.
  if (blockIsAir && airDown && humidityDown == 3 && humidity < 4) {
    temperature = 0;
  }

  // Apply air heating from ground.
  if (blockIsAir) {
    int temperatureFlow = 0;

    for (int i=0; i<6; i++) {
      if (!neighborValid[i]) continue;

      // heating only applies to non-air blocks.
      if (neighborProperties[i].r == blocksAir) continue;

      int neighborTemperature = neighborProperties[i].g;
      temperatureFlow += neighborTemperature - temperature;
    }

    if (temperatureFlow != 0 && random(78) < 0.001 * abs(float(temperatureFlow))) {
      temperature += temperatureFlow;
    }
  }

  // Simulate evaporation.
  if (blockIsAir) {
    if (humidity == 0) {
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
  } else {
    // Remove humidity due to evaporation.
    if (humidity > 0 && random(2) < 0.0001 * float(temperature)) {
      humidity--;
      temperature++;
    }
  }

  // Make it rain.
  if (blockIsAir) {
    // Remove humidity and temperature around raindrops.
    bool cloudRemoved = false;
    int raindropsCount = 0;
    int cloudsCount = 0;

    if (humidity > 0) {
      for (int dx = -5; dx <= 5; dx++) {
        for (int dy = -6; dy <= -1; dy++) {
          for (int dz = -5; dz <= 5; dz++) {
            if (dx == 0 && dy == 0 && dz == 0) continue;

            ivec3 neighborPosition = blockPosition + ivec3(dx, dy, dz);
            if (!isValidPosition(neighborPosition)) continue;

            int neighborHumidity = int(texture2D(blocksInformation, getTextureCoordinatesForPosition(neighborPosition)).b * 255.0);

            if (neighborHumidity == 4) raindropsCount++;
            if (neighborHumidity == 3) cloudsCount++;
          }
        }
      }

      if ((airDown && humidityDown < 3 || random(35) < 0.25) && random(34) < 0.05 * pow(float(raindropsCount), 4.0)) {
        if (humidity == 3) cloudRemoved = true;
        humidity = 0;
      }

      if (raindropsCount > 0) {
        if (humidity < 3) humidity = 0;
        temperature = 0;
      }
    }

    // Rain falls down.
    if (humidity == 4) {
      humidity = 0;
    } else if (airUp && humidityUp == 4) {
      humidity = 4;
    }

    // Raindrop formation requires a minimum amount of clouds.
    if (cloudsCount > 40) {
      // Spawn random raindrops from blocks on bottom of clouds.
      if (humidity == 3 && airDown && humidityDown < 3 && cloudNeighborsCount == 5 && random(1) < 0.02) {
        humidity = 4;
      }

      // When a cloud reaches the top plane it starts raining at its base.
      if (humidity == 3 && humidityDown < 3 && random(7) < 0.005) {
        ivec3 topPosition = ivec3(blockPosition.x, worldSize.y - 1.0, blockPosition.z);
        int topHumidity = int(texture2D(blocksInformation, getTextureCoordinatesForPosition(topPosition)).b * 255.0);

        if (topHumidity == 3) humidity = 4;
      }
    }

    // If cloud was removed due to being nearby a raindrop, there's a small chance to spawn rain.
    if (raindropsCount > 1 && cloudRemoved && random(88) < 0.015 * float(5 - raindropsCount)) {
      humidity = 4;
    }

  } else {
    // Accept rain.
    if (airUp && humidityUp == 4) {
      humidity++;
      if (temperature == 4) temperature--;
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

  // Clamp block properties.
  temperature = clampProperty(temperature);
  humidity = clampProperty(humidity);

  // For air, earth, and water, calculate block material from the properties.
  if (blockType <= blocksWater) {
    float materialDataIndex = float(temperature + humidity * 5);
    blockMaterial = int(texture2D(materialData, vec2((materialDataIndex + 0.5) / materialDataSize.x, (float(blockType) + 0.5) / materialDataSize.y)).r * 255.0);
  }

  gl_FragColor = vec4(blockType, temperature, humidity, blockMaterial) / 255.0;
}
