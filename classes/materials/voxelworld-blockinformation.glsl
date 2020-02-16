// Get block information for current block.
ivec3 blockPosition = ivec3(blockCoordinates);
ivec4 blockProperties = ivec4(texture2D(blocksInformation, getTextureCoordinatesForPosition(blockPosition)) * 255.0);
int blockType = blockProperties.r;
int temperature = blockProperties.g;
int humidity = blockProperties.b;
int blockMaterial = blockProperties.a;
