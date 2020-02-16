// See if the block is empty.
bool isEmpty= blockMaterial == materialsEmpty;
bool isWater = blockMaterial == materialsWater || blockMaterial == materialsRain;
bool isSolid = !isEmpty && !isWater;

// Filter which blocks to draw.
if (isEmpty && discardInvisible || isSolid && !drawSolids || isWater && !drawWater) {
  gl_Position = vec4(0);
  return;
}

// See if the neighbor towards the vertex is facing is also full.
ivec3 neighborPosition = ivec3(blockCoordinates + normal);
int neighborBlockMaterial = getBlockMaterialForPosition(neighborPosition);
bool neighborEmpty = neighborBlockMaterial == materialsEmpty;
bool neighborIsWater = neighborBlockMaterial == materialsWater || neighborBlockMaterial == materialsRain;
bool neighborIsSolid = !neighborEmpty && !neighborIsWater;

// No need to draw faces between solids themselves and water blocks themselves.
if (isSolid && neighborIsSolid || isWater && neighborIsWater) {
  gl_Position = vec4(0);
  return;
}
