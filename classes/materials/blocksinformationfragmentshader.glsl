precision mediump float;
precision mediump int;

uniform float totalGameTime;
uniform float elapsedGameTime;

varying vec2 vUv;

#include <voxelworld_common>

vec3 getPositionForTextureCoordinates(vec2 textureCoordinates) {
  float width = worldSize.x;
  float height = worldSize.y;
  float depth = worldSize.z;
  float dataWidth = blocksInformationSize.x;
  float dataHeight = blocksInformationSize.y;
  float index = floor(floor(textureCoordinates.x * dataWidth) + floor(textureCoordinates.y * dataHeight) * dataWidth);
  vec3 position;
  position.x = mod(index, width);
  index = floor(index / width);
  position.y = mod(index, height);
  index = floor(index / height);
  position.z = index;
  return position;
}

void main() {
  vec3 blockPosition = getPositionForTextureCoordinates(vUv);

  vec3 neighborPosition = blockPosition;
  neighborPosition.y = mod(neighborPosition.y + 1.0, worldSize.y);

  if (isValidPosition(neighborPosition)) {
    vec2 neighborBlockCoordinates = getTextureCoordinatesForPosition(neighborPosition);
    vec4 color = texture2D(blocksInformation, neighborBlockCoordinates);
    gl_FragColor = color;
  } else {
    gl_FragColor = vec4(0.0);
  }
}
