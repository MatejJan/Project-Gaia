'use strict'

ProjectGaia.VegetationTypes =
  Empty: 0

  # Trees
  TreeBirchSmall: null
  TreeBirchSmall2: null
  TreeOak: null
  TreeOakLarge: null
  TreePineTundra: null
  TreeRainforest1: null
  TreeSoil1: null
  TreeSoil2: null
  TreeSoilSmall: null

  # Shrubs
  ShrubAgave: null
  ShrubAgave2: null
  ShrubBlueberry: null
  ShrubBush1: null
  ShrubBush2: null
  ShrubBushLong: null
  ShrubCushionPlants1: null
  ShrubCushionPlants2: null
  ShrubCushionPlants3: null
  ShrubDwarfColumnar: null
  ShrubElderberry: null
  ShrubSambucus: null

vegetationTypeIndex = 1

for vegetationTypeName of ProjectGaia.VegetationTypes when not ProjectGaia.VegetationTypes[vegetationTypeName]?
  ProjectGaia.VegetationTypes[vegetationTypeName] = vegetationTypeIndex
  vegetationTypeIndex++
