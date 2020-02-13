uniform float totalGameTime;
uniform float elapsedGameTime;

uniform sampler2D vegetationInformation;
uniform vec2 vegetationInformationSize;

varying vec2 vUv;

const vec2 K1 = vec2(23.14069263277926,2.665144142690225);

ivec3 getPositionForTextureCoordinates(vec2 textureCoordinates) {
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
  return ivec3(position);
}

float randomLowPrecision(float counter) {
  return fract(cos(dot(vec2(vUv.x + totalGameTime, vUv.y + counter), K1)) * 12345.6789);
}

float random(int counter) {
  // Construct high precision random by adding two random values at different digit places.
  return randomLowPrecision(float(counter)) + 0.001 * randomLowPrecision(float(counter) + 12345.6789);
}

int max(int a, int b) {
  if (a > b) return a;
  return b;
}

int min(int a, int b) {
  if (a < b) return a;
  return b;
}

int abs(int a) {
  if (a < 0) return -a;
  return a;
}
