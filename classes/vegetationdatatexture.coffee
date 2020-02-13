'use strict'

class ProjectGaia.VegetationDataTexture extends THREE.DataTexture
  constructor: ->
    vegetationTypesCount = _.keys(ProjectGaia.VegetationTypes).length

    width = 4096
    height = vegetationTypesCount

    dataArray = new Uint8Array width * height

    # Embed material mappings.
    for vegetationTypeName, vegetationTypeIndex of ProjectGaia.VegetationTypes when vegetationTypeIndex
      rowOffset = vegetationTypeIndex * width

      # Write dimensions of the model.
      model = ProjectGaia.VoxelWorld.vegetationModels[vegetationTypeIndex]
      dataArray[rowOffset] = model.width
      dataArray[rowOffset + 1] = model.height
      dataArray[rowOffset + 2] = model.depth

      modelOffset = rowOffset + 3

      for z in [0...model.depth]
        for y in [0...model.height]
          for x in [0...model.width]
            index = modelOffset + x + y * model.width + z * model.width * model.height

            blockMaterial = model.blocks[x][y][z].material
            dataArray[index] = blockMaterial
            dataArray[index + 1] = if blockMaterial then 255 else 0

    super dataArray, width, height, THREE.AlphaFormat
