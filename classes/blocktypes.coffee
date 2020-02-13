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
  Rain: 15
  Cloud: 16

  # Earth
  Rock: 1
  FrozenRock: 2
  Soil: 3
  Snow: 4
  Gravel: 5
  Sand: 6
  Mud: 7

  # Water
  Ice: 8
  Water: 9
  Swamp: 10
  Steam: 11

  Unknown1: 12
  Unknown2: 13
  Unknown3: 14
  Unknown4: 17
  Unknown5: 18
  Unknown6: 19
  Unknown7: 20
  Unknown8: 21

class ProjectGaia.BlockMaterialMapping
  constructor: (@mapping) ->

  getBlockMaterialForProperties: (propertiesOrTemperature, humidity) ->
    if _.isObject propertiesOrTemperature
      temperature = propertiesOrTemperature.temperature
      humidity = propertiesOrTemperature.humidty

    else
      temperature = propertiesOrTemperature

    @mapping[humidity][temperature]
