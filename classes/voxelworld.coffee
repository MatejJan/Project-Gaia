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
      [Materials.Cloud, Materials.Cloud, Materials.Cloud, Materials.Cloud, Materials.Cloud]
      [Materials.Rain, Materials.Rain, Materials.Rain, Materials.Rain, Materials.Rain]
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

  colorFromRGB = (r, g, b) => new THREE.Color().setIntegerRGB r, g, b

  @BlockMaterialProperties: []

  @BlockMaterialProperties[Materials.Cloud] = blockType: Types.Water, color: colorFromRGB(188, 212, 223)
  @BlockMaterialProperties[Materials.Rain] = blockType: Types.Water, color: colorFromRGB(59, 128, 149)

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

  @BlockMaterialProperties[Materials.Unknown1] = blockType: Types.Vegetation, color: colorFromRGB(160, 128, 66)
  @BlockMaterialProperties[Materials.Unknown2] = blockType: Types.Vegetation, color: colorFromRGB(103, 108, 26)
  @BlockMaterialProperties[Materials.Unknown3] = blockType: Types.Vegetation, color: colorFromRGB(89, 65, 38)
  @BlockMaterialProperties[Materials.Unknown4] = blockType: Types.Vegetation, color: colorFromRGB(163, 187, 71)
  @BlockMaterialProperties[Materials.Unknown5] = blockType: Types.Vegetation, color: colorFromRGB(101, 116, 35)
  @BlockMaterialProperties[Materials.Unknown6] = blockType: Types.Vegetation, color: colorFromRGB(130, 77, 69)
  @BlockMaterialProperties[Materials.Unknown7] = blockType: Types.Vegetation, color: colorFromRGB(207, 204, 190)
  @BlockMaterialProperties[Materials.Unknown8] = blockType: Types.Vegetation, color: colorFromRGB(37, 28, 22)

  @getMaterialIndexForColor: (colorOrR, g, b) ->
    if colorOrR instanceof THREE.Color
      color = colorOrR

    else
      r = colorOrR
      color = colorFromRGB r, g, b

    materialIndex = _.findIndex @BlockMaterialProperties, (blockMaterialProperties) => blockMaterialProperties?.color.equals color

    if materialIndex >= 0 then materialIndex else null

  @getPropertiesForMaterial: (blockMaterial) ->
    for blockMaterialMapping, blockType in @BlockMaterialMappings
      for temperature in [0..4]
        for humidity in [0..4]
          if blockMaterialMapping.getBlockMaterialForProperties(temperature, humidity) is blockMaterial
            return {temperature, humidity}

    null

  Vegetation = ProjectGaia.VegetationTypes

  @VegetationProperties: []
  @VegetationProperties[Vegetation.Cactus] = modelName: 'cactus'
  @VegetationProperties[Vegetation.PineTree] = modelName: 'tree-pine-small'
  @VegetationProperties[Vegetation.PalmTree] = modelName: 'tree-palm-desert'
  @VegetationProperties[Vegetation.BirchTree] = modelName: 'tree-birch-soil-tundra'

  @load: (loadingManager) ->
    @environmentModel = new ProjectGaia.VoxelModel
      url: 'content/environments/32x32materials.vox'
      loadingManager: loadingManager

    @vegetationModels = []

    for vegetationProperties, vegetationTypeIndex in @VegetationProperties when vegetationTypeIndex
      @vegetationModels[vegetationTypeIndex] = new ProjectGaia.VoxelModel
        url: "content/vegetation/#{vegetationProperties.modelName}.vox"
        loadingManager: loadingManager

  constructor: (@options) ->
    dataWidth = 512
    dataHeight = 512

    blocksInformationArray = new Uint8Array dataWidth * dataHeight * 4
    blocksInformationArray.fill 255

    for z in [0...@options.depth]
      for y in [0...@options.height]
        for x in [0...@options.width]
          index = @getBlockIndexForCoordinates(x, y, z) * 4

          block = @constructor.environmentModel.blocks[x][y][z]
          materialProperties = @constructor.getPropertiesForMaterial block.material

          blocksInformationArray[index] = block.type
          blocksInformationArray[index + 1] = materialProperties?.temperature or 0
          blocksInformationArray[index + 2] = materialProperties?.humidity or 0
          blocksInformationArray[index + 3] = block.material

    @startingBlocksInformationTexture = new THREE.DataTexture blocksInformationArray, dataWidth, dataHeight, THREE.RGBAFormat

  getBlockIndexForCoordinates: (x, y, z) ->
    x + y * @options.width + z * @options.width * @options.height
