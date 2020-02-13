'use strict'

ProjectGaia.BlockTypes =
  Air: 0
  Earth: 1
  Water: 2
  Vegetation: 3
  Custom: 4

ProjectGaia.BlockMaterials =
  # Air
  Empty: 0
  Rain: null
  Cloud: null

  # Earth
  Rock: null
  FrozenRock: null
  Soil: null
  Snow: null
  Gravel: null
  Sand: null
  Mud: null

  # Water
  Ice: null
  Water: null
  Swamp: null
  Steam: null

blockMaterialIndex = 1

for blockMaterialName of ProjectGaia.BlockMaterials when not ProjectGaia.BlockMaterials[blockMaterialName]?
  ProjectGaia.BlockMaterials[blockMaterialName] = blockMaterialIndex
  blockMaterialIndex++

class ProjectGaia.BlockMaterialMapping
  constructor: (@mapping) ->

  getBlockMaterialForProperties: (propertiesOrTemperature, humidity) ->
    if _.isObject propertiesOrTemperature
      temperature = propertiesOrTemperature.temperature
      humidity = propertiesOrTemperature.humidity

    else
      temperature = propertiesOrTemperature

    @mapping[humidity][temperature]
