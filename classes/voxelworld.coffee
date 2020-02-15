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

  @BlockMaterialProperties[Materials.Cloud] = blockType: Types.Water, color: colorFromRGB(188, 212, 224)
  @BlockMaterialProperties[Materials.Rain] = blockType: Types.Water, color: colorFromRGB(59, 128, 150)

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

  @registerCustomMaterial: (color) ->
    materialIndex = _.keys(ProjectGaia.BlockMaterials).length
    materialName = "Unknown#{materialIndex}"

    ProjectGaia.BlockMaterials[materialName] = materialIndex
    @BlockMaterialProperties[materialIndex] = blockType: Types.Custom, color: color

    # Return the new material index.
    materialIndex

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

  @VegetationProperties: []

  for vegetationTypeName, vegetationTypeIndex of ProjectGaia.VegetationTypes when vegetationTypeIndex
     @VegetationProperties[vegetationTypeIndex] = modelName: _.kebabCase vegetationTypeName

  @load: (loadingManager) ->
    environmentNames = [
      '32x32x32-materials'
      '40x40x30-island-snow-rock'
      '40x40x30-island-soil-mud'
      '40x40x39-tunnel'
      '40x40x40-rock-canyon-sand-soil'
      '50x50x40-island-soil-sand-mud'
      '120x120x60-big'
    ]

    urlParameters = new URLSearchParams window.location.search
    worldIndex = urlParameters.get('world') or 0

    @environmentModel = new ProjectGaia.VoxelModel
      url: "content/environments/#{environmentNames[worldIndex]}.vox"
      loadingManager: loadingManager

    @vegetationModels = []

    for vegetationProperties, vegetationTypeIndex in @VegetationProperties when vegetationTypeIndex
      @vegetationModels[vegetationTypeIndex] = new ProjectGaia.VoxelModel
        url: "content/vegetation/#{vegetationProperties.modelName}.vox"
        loadingManager: loadingManager

  constructor: (@options) ->
    dataWidth = 2048
    dataHeight = 1024

    blocksInformationArray = new Uint8Array dataWidth * dataHeight * 4
    blocksInformationArray.fill 0

    environmentModel = @constructor.environmentModel

    for z in [0...environmentModel.depth]
      for y in [0...environmentModel.height]
        for x in [0...environmentModel.width]
          index = @getBlockIndexForCoordinates(x, y, z) * 4

          block = environmentModel.blocks[x][y][z]
          materialProperties = @constructor.getPropertiesForMaterial block.material

          blocksInformationArray[index] = block.type
          blocksInformationArray[index + 1] = materialProperties?.temperature or 0
          blocksInformationArray[index + 2] = materialProperties?.humidity or 0
          blocksInformationArray[index + 3] = block.material

    @startingBlocksInformationTexture = new THREE.DataTexture blocksInformationArray, dataWidth, dataHeight, THREE.RGBAFormat

  getBlockIndexForCoordinates: (x, y, z) ->
    x + y * @options.width + z * @options.width * @options.height
