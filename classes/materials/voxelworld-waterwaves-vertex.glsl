// Make water blocks wave.
if (blockMaterial == materialsWater) {
  // See if this is the surface of the water.
  ivec3 neighborUpPosition = ivec3(blockCoordinates + vec3(0, 1, 0));
  int neighborUpBlockMaterial = getBlockMaterialForPosition(neighborUpPosition);
  bool blockIsWaterSurface = neighborUpBlockMaterial != materialsWater;

  if (blockIsWaterSurface) {
    // See if this is the top of the block.
    if (position.y > blockCoordinates.y) {
      float wavePhase = totalGameTime + position.x * 0.2;
      float waveDisplacement = pow((sin(wavePhase) + 1.0) * 0.5, 5.0);

      float wavePhase2 = 1.2 + totalGameTime * 0.5 + position.z * 0.05;
      waveDisplacement += pow((sin(wavePhase2) + 1.0) * 0.5, 3.0);

      float wavesCount = 2.0;
      transformed.y += waveDisplacement / wavesCount * 0.7 - 0.4;

      #ifdef computeWaterNormal
        float waveDerivativeX = 0.03125 * cos(wavePhase) * pow(1.0 + sin(wavePhase), 4.0);
        float waveDerivativeZ = 0.01875 * cos(wavePhase2) * pow(1.0 + sin(wavePhase2), 2.0);
        transformedNormal = vec3(waveDerivativeX, 1.0, waveDerivativeZ);
      #endif
    }
  }
}
