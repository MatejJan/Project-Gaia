'use strict'

class ProjectGaia.Materials
  @getTimeUniforms: ->
    elapsedGameTime:
      value: 0
    totalGameTime:
      value: 0

  @updateTimeUniforms: (uniforms, gameTime) ->
    uniforms.elapsedGameTime.value = gameTime.elapsedGameTime
    uniforms.totalGameTime.value = gameTime.totalGameTime
