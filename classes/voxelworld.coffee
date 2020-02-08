'use strict'

class ProjectGaia.VoxelWorld
  Types = ProjectGaia.BlockTypes
  Materials = ProjectGaia.BlockMaterials

  @BlockMaterialMappings: [
    # Air
    new ProjectGaia.BlockMaterialMapping [
      [Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty]
      [Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty]
      [Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty]
      [Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty]
      [Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty]
    ]
  ,
    # Earth
    new ProjectGaia.BlockMaterialMapping [
      [Materials.Rock, Materials.Rock, Materials.Gravel, Materials.Gravel, Materials.Sand]
      [Materials.Rock, Materials.Soil, Materials.Soil, Materials.Gravel, Materials.Sand]
      [Materials.Snow, Materials.Soil, Materials.Soil, Materials.Soil, Materials.Sand]
      [Materials.FrozenRock, Materials.Soil, Materials.Soil, Materials.Mud, Materials.Mud]
      [Materials.FrozenRock, Materials.Snow, Materials.Mud, Materials.Mud, Materials.Mud]
    ]
  ,
    # Water
    new ProjectGaia.BlockMaterialMapping [
      [Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty]
      [Materials.Ice, Materials.Water, Materials.Water, Materials.Water, Materials.Steam]
      [Materials.Ice, Materials.Water, Materials.Water, Materials.Water, Materials.Steam]
      [Materials.Ice, Materials.Water, Materials.Swamp, Materials.Swamp, Materials.Steam]
      [Materials.Ice, Materials.Water, Materials.Swamp, Materials.Swamp, Materials.Steam]
    ]
  ]

  colorFromRGB = (r, g, b) =>
    new THREE.Color(r / 255, g / 255, b / 255)

  @BlockMaterialProperties: []

  @BlockMaterialProperties[Materials.Rock] = blockType: Types.Earth, color: colorFromRGB(78, 78, 86)
  @BlockMaterialProperties[Materials.FrozenRock] = blockType: Types.Earth, color: colorFromRGB(130, 173, 179)
  @BlockMaterialProperties[Materials.Soil] = blockType: Types.Earth, color: colorFromRGB(157, 107, 80)
  @BlockMaterialProperties[Materials.Snow] = blockType: Types.Earth, color: colorFromRGB(242, 238, 204)
  @BlockMaterialProperties[Materials.Gravel] = blockType: Types.Earth, color: colorFromRGB(122, 113, 89)
  @BlockMaterialProperties[Materials.Sand] = blockType: Types.Earth, color: colorFromRGB(231, 210, 130)
  @BlockMaterialProperties[Materials.Mud] = blockType: Types.Earth, color: colorFromRGB(108, 74, 74)

  @BlockMaterialProperties[Materials.Ice] = blockType: Types.Water, color: colorFromRGB(188, 212, 223)
  @BlockMaterialProperties[Materials.Water] = blockType: Types.Water, color: colorFromRGB(59, 128, 149)
  @BlockMaterialProperties[Materials.Swamp] = blockType: Types.Water, color: colorFromRGB(75, 89, 61)
  @BlockMaterialProperties[Materials.Steam] = blockType: Types.Water, color: colorFromRGB(228, 216, 202)

  @BlockMaterialProperties[Materials.Unknown1] = blockType: Types.Earth, color: colorFromRGB(160, 128, 66)
  @BlockMaterialProperties[Materials.Unknown2] = blockType: Types.Earth, color: colorFromRGB(103, 108, 26)
  @BlockMaterialProperties[Materials.Unknown3] = blockType: Types.Earth, color: colorFromRGB(89, 65, 38)

  @getMaterialIndexForColor: (colorOrR, g, b) ->
    if colorOrR instanceof THREE.Color
      color = colorOrR
    else
      color = colorFromRGB r, g, b

    _.findIndex @BlockMaterialProperties, (blockMaterialProperties) => blockMaterialProperties.color.equals color

  constructor: (@options) ->
    dataWidth = 512
    dataHeight = 512

    blocksInformationArray = new Uint8Array dataWidth * dataHeight * 4
    blocksInformationArray.fill 255

    for z in [0...@options.depth]
      for y in [0...@options.height]
        for x in [0...@options.width]
          index = @getBlockIndexForCoordinates(x, y, z) * 4

          blockType = Math.floor(Math.random() * 3)
          blockMaterial = Math.max(0, Math.floor(Math.random() * 1014 - 1000))
          blockProperties =
            temperature: Math.floor(Math.random() * 5)
            humidity: Math.floor(Math.random() * 5)

          blocksInformationArray[index] = blockType
          blocksInformationArray[index + 1] = blockProperties.temperature
          blocksInformationArray[index + 2] = blockProperties.humidity
          blocksInformationArray[index + 3] = blockMaterial
          blocksInformationArray[index] = blockMaterial * 10

    @startingBlocksInformationTexture = new THREE.DataTexture blocksInformationArray, dataWidth, dataHeight, THREE.RGBAFormat

  getBlockIndexForCoordinates: (x, y, z) ->
    x + y * @options.width + z * @options.width * @options.height
