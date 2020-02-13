'use strict'

class ProjectGaia.Materials
  @getTimeUniforms: ->
    elapsedGameTime:
      value: 0
    totalGameTime:
      value: 0

  @getRandomUniforms: ->
    randomSeed:
      value: Math.random()

  @updateTimeUniforms: (uniforms, gameTime) ->
    uniforms.elapsedGameTime.value = gameTime.elapsedGameTime
    uniforms.totalGameTime.value = gameTime.totalGameTime

  @updateRandomUniforms: (uniforms) ->
    uniforms.randomSeed.value = Math.random()

  @getTypeDefines: ->
    defines = {}

    for blockMaterial, blockMaterialIndex of ProjectGaia.BlockMaterials
      defines["materials#{_.upperFirst blockMaterial}"] = blockMaterialIndex

    for vegetationType, vegetationTypeIndex of ProjectGaia.VegetationTypes
      defines["vegetation#{_.upperFirst vegetationType}"] = vegetationTypeIndex

    defines
