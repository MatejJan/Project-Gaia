'use strict'

class ProjectGaia.MaterialsDataTexture extends THREE.DataTexture
  constructor: ->
    blockTypesCount = _.keys(ProjectGaia.BlockTypes).length

    width = 32
    height = blockTypesCount + 1

    dataArray = new Uint8Array width * height * 3

    # Embed material mappings.
    for blockType, blockTypeIndex of ProjectGaia.BlockTypes
      continue unless materialMapping = ProjectGaia.VoxelWorld.BlockMaterialMappings[blockTypeIndex]
      y = blockTypeIndex

      for temperature in [0..4]
        for humidity in [0..4]
          x = temperature + humidity * 5
          pixelOffset = (x + y * width) * 3

          dataArray[pixelOffset] = materialMapping.getBlockMaterialForProperties temperature, humidity

    # Embed palette colors.
    paletteRow = blockTypesCount

    for blockMaterial, blockMaterialIndex of ProjectGaia.BlockMaterials
      continue unless blockMaterialProperties = ProjectGaia.VoxelWorld.BlockMaterialProperties[blockMaterialIndex]

      pixelOffset = (blockMaterialIndex + paletteRow * width) * 3
      color = blockMaterialProperties.color

      dataArray[pixelOffset] = color.r * 255
      dataArray[pixelOffset + 1] = color.g * 255
      dataArray[pixelOffset + 2] = color.b * 255

    super dataArray, width, height, THREE.RGBFormat
