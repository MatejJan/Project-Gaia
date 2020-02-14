precision highp float;
precision highp int;

uniform sampler2D vegetationData;
uniform vec2 vegetationDataSize;

#include <voxelworld_common>
#include <computedtexture_common>

ivec3 unpackVoxelPosition(ivec2 components) {
  int x = int(floor(float(components.x) / 16.0));
  int y = components.y;
  int z = int(mod(float(components.x), 16.0));
  return ivec3(x, y, z);
}

ivec2 packVoxelPosition(ivec3 position) {
  int x = position.x * 16 + position.z;
  int y = position.y;
  return ivec2(x, y);
}

ivec3 getModelSize(int vegetationType) {
  vec2 uv = vec2(0.5 / vegetationDataSize.x, (float(vegetationType) + 0.5) / vegetationDataSize.y);
  int width = int(texture2D(vegetationData, uv).a * 255.0);

  uv.x = 1.5 / vegetationDataSize.x;
  int height = int(texture2D(vegetationData, uv).a * 255.0);

  uv.x = 2.5 / vegetationDataSize.x;
  int depth = int(texture2D(vegetationData, uv).a * 255.0);

  return ivec3(width, height, depth);
}

bool isValidModelPosition(ivec3 modelVoxelPosition, ivec3 modelSize) {
  return modelVoxelPosition.x >= 0 && modelVoxelPosition.x < modelSize.x &&
         modelVoxelPosition.y >= 0 && modelVoxelPosition.y < modelSize.y &&
         modelVoxelPosition.z >= 0 && modelVoxelPosition.z < modelSize.z;
}

ivec3 getRootVoxelPosition(int vegetationType) {
  ivec3 modelSize = getModelSize(vegetationType);

  // Root voxel is in the middle of the bottom layer.
  return ivec3(modelSize.x / 2, 0, modelSize.z / 2);
}

int getMaterialForModel(int vegetationType, ivec3 position) {
  ivec3 modelSize = getModelSize(vegetationType);
  int voxelIndex = position.x + position.y * modelSize.x + position.z * modelSize.x * modelSize.y;

  vec2 uv = vec2((3.0 + float(voxelIndex)) / vegetationDataSize.x, (float(vegetationType) + 0.5) / vegetationDataSize.y);
  return int(texture2D(vegetationData, uv).a * 255.0);
}

vec4 getOutputData(int vegetationType, ivec3 voxelPosition) {
  vec2 packedVoxelPosition = vec2(packVoxelPosition(voxelPosition));
  float vegetationMaterial = float(getMaterialForModel(vegetationType, voxelPosition));

  return vec4(vegetationType, packedVoxelPosition.x, packedVoxelPosition.y, vegetationMaterial) / 255.0;
}

int pickRandomVegetationType(int[16] vegetationTypes) {
  float vegetationTypesCount = 0.0;
  for (int i = 0; i < 16; i++) {
    if (vegetationTypes[i] > 0) {
      vegetationTypesCount++;
    } else {
      break;
    }
  }

  int randomIndex = int(random(99) * vegetationTypesCount);

  #pragma unroll_loop
  for ( int i = 0; i < 16; i ++ ) {

    if (randomIndex == 0) return vegetationTypes[ i ];
    randomIndex--;

  }

  return 0;
}

void main() {
  ivec3 blockPosition = getPositionForTextureCoordinates(vUv);
  if (!isValidPosition(blockPosition)) {
    return;
  }

  vec2 blockCoordinates = getTextureCoordinatesForPosition(blockPosition);

  ivec4 vegetationProperties = ivec4(texture2D(vegetationInformation, blockCoordinates) * 255.0);

  int vegetationType = vegetationProperties.r;
  ivec3 voxelPosition = unpackVoxelPosition(vegetationProperties.gb);
  int vegetationMaterial = vegetationProperties.a;

  ivec4 blockProperties = ivec4(texture2D(blocksInformation, blockCoordinates) * 255.0);
  int blockMaterial = blockProperties.a;

  ivec3 integerWorldSize = ivec3(worldSize);

  if (vegetationMaterial == 0 && blockMaterial == 0) {
    // Look at all neighbors to see if we can grow.
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        for (int dz = -1; dz <= 1; dz++) {
          if (dx == 0 && dy == 0 && dz == 0) continue;

          ivec3 neighborPosition = blockPosition + ivec3(dx, dy, dz);
          if (!isValidPosition(neighborPosition)) continue;

          vec2 neighborBlockCoordinates = getTextureCoordinatesForPosition(neighborPosition);

          ivec4 neighborVegetationProperties = ivec4(texture2D(vegetationInformation, neighborBlockCoordinates) * 255.0);
          int neighborVegetationMaterial = neighborVegetationProperties.a;

          if (neighborVegetationMaterial > 0) {
            // See if we should grow this turn.
            int distance = abs(dx) + abs(dy) + abs(dz);
            if (random(1) < 0.01 * float(4 - distance)) {
              // We're neighboring a vegetation block. Extend it to this block if possible.
              int neighborVegetationType = neighborVegetationProperties.r;
              ivec3 modelSize = getModelSize(neighborVegetationType);

              // Get where in the model is the neighbor.
              ivec3 nieghborModelVoxelPosition = unpackVoxelPosition(neighborVegetationProperties.gb);

              // Calculate where our voxel would be in the model.
              ivec3 modelVoxelPosition = nieghborModelVoxelPosition - ivec3(dx, dy, dz);

              // See if our position is still inside the model.
              if (isValidModelPosition(modelVoxelPosition, modelSize)) {
                // Extend neighbor vegetation.
                vegetationType = neighborVegetationType;
                voxelPosition = modelVoxelPosition;

                gl_FragColor = getOutputData(vegetationType, voxelPosition);
                return;
              }
            }
          } else {
            // See if we're analyzing the neighbor beneath this block.
            if (dx == 0 && dy == -1 && dz == 0) {
              // See if we should grow this turn.
              if (random(2) < 0.0005) {
                // Analyze the material we're growing on.
                ivec4 neighborBlockProperties = ivec4(texture2D(blocksInformation, neighborBlockCoordinates) * 255.0);
                int neighborBlockMaterial = neighborBlockProperties.a;
                int vegetationTypes[16];

                if (neighborBlockMaterial == materialsFrozenRock || neighborBlockMaterial == materialsSnow) {
                  vegetationTypes[0] = vegetationTreePineTundra;
                  vegetationTypes[1] = vegetationShrubCushionPlants1;
                  vegetationTypes[2] = vegetationShrubCushionPlants2;
                  vegetationTypes[3] = vegetationShrubCushionPlants3;
                  vegetationTypes[4] = vegetationTreePineTundra;
                  vegetationTypes[5] = vegetationTreePineTundra;
                  vegetationTypes[6] = vegetationTreePineTundra;
                  vegetationTypes[7] = vegetationTreePineTundra;

                } else if (neighborBlockMaterial == materialsSoil) {
                  vegetationTypes[0] = vegetationTreeBirchSmall;
                  vegetationTypes[1] = vegetationTreeBirchSmall2;
                  vegetationTypes[2] = vegetationTreeOak;
                  vegetationTypes[3] = vegetationTreeOakLarge;
                  vegetationTypes[4] = vegetationTreeSoil1;
                  vegetationTypes[5] = vegetationTreeSoil2;
                  vegetationTypes[6] = vegetationTreeSoilSmall;
                  vegetationTypes[7] = vegetationShrubSambucus;
                  vegetationTypes[8] = vegetationShrubBlueberry;
                  vegetationTypes[9] = vegetationShrubBush1;
                  vegetationTypes[10] = vegetationShrubBush2;
                  vegetationTypes[11] = vegetationShrubBushLong;
                  vegetationTypes[12] = vegetationShrubElderberry;

                } else if (neighborBlockMaterial == materialsGravel) {
                  vegetationTypes[0] = vegetationShrubAgave;
                  vegetationTypes[1] = vegetationShrubAgave2;
                  vegetationTypes[2] = vegetationShrubCushionPlants1;
                  vegetationTypes[3] = vegetationShrubCushionPlants2;
                  vegetationTypes[4] = vegetationShrubCushionPlants3;
                  vegetationTypes[5] = vegetationShrubBush1;
                  vegetationTypes[6] = vegetationShrubBush2;
                  vegetationTypes[7] = vegetationShrubDwarfColumnar;

                } else if (neighborBlockMaterial == materialsSand) {
                  vegetationTypes[0] = vegetationShrubAgave;
                  vegetationTypes[1] = vegetationShrubAgave2;

                } else if (neighborBlockMaterial == materialsMud) {
                  vegetationTypes[0] = vegetationTreeOak;
                  vegetationTypes[1] = vegetationTreeOakLarge;
                  vegetationTypes[2] = vegetationTreeRainforest1;
                  vegetationTypes[3] = vegetationShrubBush1;
                  vegetationTypes[4] = vegetationShrubBush2;
                  vegetationTypes[5] = vegetationShrubBushLong;
                  vegetationTypes[6] = vegetationShrubSambucus;

                } else {
                  continue;
                }

                vegetationType = pickRandomVegetationType(vegetationTypes);
                voxelPosition = getRootVoxelPosition(vegetationType);
                gl_FragColor = getOutputData(vegetationType, voxelPosition);
                return;
              }
            }
          }
        }
      }
    }
  }

  // No change was made, simply pass on previous properties.
  gl_FragColor = vec4(vegetationProperties) / 255.0;
}
