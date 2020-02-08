// Get block information for current block.
vec4 blockInformation = texture2D(blocksInformation, getTextureCoordinatesForPosition(blockPosition));

// See if the block is empty.
int blockMaterial = int(blockInformation.a * 255.0);
if (blockMaterial == 0) {
  gl_Position = vec4(0);
  return;
}

// See if the neighbor towards the vertex is facing is empty.
vec3 neighborPosition = blockPosition + normal;
if (isValidPosition(neighborPosition)) {
  int neighborBlockMaterial = int(texture2D(blocksInformation, getTextureCoordinatesForPosition(neighborPosition)).a * 255.0);
  if (neighborBlockMaterial > 0) {
    gl_Position = vec4(0);
    return;
  }
}
