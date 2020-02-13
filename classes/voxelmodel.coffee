class ProjectGaia.VoxelModel
  constructor: (@options) ->
    @options.loadingManager.itemStart @options.url

    parser = new vox.Parser()
    parser.parse(@options.url).then (data) =>
      @width = data.size.x
      @height = data.size.z
      @depth = data.size.y

      @sizeVector = new THREE.Vector3().copy data.size

      @colors = for color in data.palette
        new THREE.Color().setIntegerRGB color

      @blocks = []

      for x in [0...@width]
        @blocks[x] = []

        for y in [0...@height]
          @blocks[x][y] = []

          for z in [0...@depth]
            @blocks[x][y][z] = type: 0, material: 0

      for voxel in data.voxels
        materialIndex = ProjectGaia.VoxelWorld.getMaterialIndexForColor @colors[voxel.colorIndex]

        # Register material if we didn't recognize it.
        materialIndex ?= ProjectGaia.VoxelWorld.registerCustomMaterial @colors[voxel.colorIndex]

        materialProperties = ProjectGaia.VoxelWorld.BlockMaterialProperties[materialIndex]

        @blocks[voxel.x][voxel.z][@depth - 1 - voxel.y] =
          material: materialIndex
          type: materialProperties.blockType

      @options.loadingManager.itemEnd @options.url
