'use strict'

class ProjectGaia.VoxelWorld
  constructor: (@options) ->

  getBlockIndexForCoordinates: (x, y, z) ->
    x + y * @options.width + z * @options.width * @options.height
