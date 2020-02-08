uniform vec3 worldSize;
uniform sampler2D blocksInformation;
uniform vec2 blocksInformationSize;

vec2 getTextureCoordinatesForPosition(vec3 position) {
  float width = worldSize.x;
  float height = worldSize.y;
  float dataWidth = blocksInformationSize.x;
  float dataHeight = blocksInformationSize.y;
  float index = position.x + position.y * width + position.z * width * height;
  return vec2((mod(index, dataWidth) + 0.5) / dataWidth, (floor(index / dataWidth) + 0.5) / dataHeight);
}

bool isValidPosition(vec3 position) {
  return (position.x >= 0.0 && position.x < worldSize.x &&
  position.y >= 0.0 && position.y < worldSize.x &&
  position.z >= 0.0 && position.z < worldSize.x);
}

int getBlockMaterialForPosition(vec3 position) {
  if (!isValidPosition(position)) return 0;
  return int(texture2D(blocksInformation, getTextureCoordinatesForPosition(position)).a * 255.0);
}
