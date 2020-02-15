uniform float totalGameTime;
uniform float elapsedGameTime;
uniform float randomSeed;

uniform sampler2D vegetationInformation;
uniform vec2 vegetationInformationSize;

varying vec2 vUv;

const vec2 K1 = vec2(23.14069263277926,2.665144142690225);

int mod(int a, int b) {
  int whole = a / b;
  return a - whole * b;
}

int sign(int a) {
  if (a > 0) return 1;
  if (a < 0) return -1;
  return 0;
}

ivec3 getPositionForTextureCoordinates(vec2 textureCoordinates) {
  int width = int(worldSize.x);
  int height = int(worldSize.y);
  int depth = int(worldSize.z);
  int dataWidth = int(blocksInformationSize.x);
  int dataHeight = int(blocksInformationSize.y);
  int index = int(textureCoordinates.x * float(dataWidth)) + int(textureCoordinates.y * float(dataHeight)) * dataWidth;
  ivec3 position;
  position.x = mod(index, width);
  index /= width;
  position.y = mod(index, height);
  index /= height;
  position.z = index;
  return ivec3(position);
}

float randomLowPrecision(float counter) {
  return fract(cos(dot(vec2(vUv.x + randomSeed, vUv.y + counter), K1)) * 12345.6789);
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
