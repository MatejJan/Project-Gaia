uniform vec3 worldSize;

uniform sampler2D blocksInformation;
uniform vec2 blocksInformationSize;

uniform sampler2D materialData;
uniform vec2 materialDataSize;

vec2 getTextureCoordinatesForPosition(ivec3 position) {
  int width = int(worldSize.x);
  int height = int(worldSize.y);
  float dataWidth = float(blocksInformationSize.x);
  float dataHeight = float(blocksInformationSize.y);
  float index = float(position.x + position.y * width + position.z * width * height);
  return vec2((mod(index, dataWidth) + 0.5) / dataWidth, (floor(index / dataWidth) + 0.5) / dataHeight);
}

bool isValidPosition(ivec3 position) {
  return position.x >= 0 && position.x < int(worldSize.x) &&
         position.y >= 0 && position.y < int(worldSize.y) &&
         position.z >= 0 && position.z < int(worldSize.z);
}

int getBlockMaterialForPosition(ivec3 position) {
  if (!isValidPosition(position)) return 0;
  return int(texture2D(blocksInformation, getTextureCoordinatesForPosition(position)).a * 255.0);
}
