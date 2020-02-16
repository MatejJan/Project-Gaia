'use strict'

class ProjectGaia.Materials.VoxelWorld extends THREE.ShaderMaterial
  @load: (loadingManager) ->
    new THREE.FileLoader(loadingManager).load 'classes/materials/voxelworld-vertex.glsl', (@vertexShader) =>
    new THREE.FileLoader(loadingManager).load 'classes/materials/voxelworld-fragment.glsl', (@fragmentShader) =>

    new THREE.FileLoader(loadingManager).load 'classes/materials/voxelworld-common.glsl', (shaderChunk) =>
      THREE.ShaderChunk.voxelworld_common = shaderChunk

    new THREE.FileLoader(loadingManager).load 'classes/materials/voxelworld-parameters-vertex.glsl', (shaderChunk) =>
      THREE.ShaderChunk.voxelworld_pars_vertex = shaderChunk

    new THREE.FileLoader(loadingManager).load 'classes/materials/voxelworld-blockinformation.glsl', (shaderChunk) =>
      THREE.ShaderChunk.voxelworld_blockinformation = shaderChunk

    new THREE.FileLoader(loadingManager).load 'classes/materials/voxelworld-discardinvisible-vertex.glsl', (shaderChunk) =>
      THREE.ShaderChunk.voxelworld_discardinvisible_vertex = shaderChunk

    new THREE.FileLoader(loadingManager).load 'classes/materials/voxelworld-waterwaves-vertex.glsl', (shaderChunk) =>
      THREE.ShaderChunk.voxelworld_waterwaves_vertex = shaderChunk

    new THREE.FileLoader(loadingManager).load 'classes/materials/computedtexture-common.glsl', (shaderChunk) =>
      THREE.ShaderChunk.computedtexture_common = shaderChunk

    new THREE.TextureLoader(loadingManager).load 'content/tileset.png', (@tilesetTexture) =>
      @tilesetTexture.minFilter = THREE.NearestFilter
      @tilesetTexture.magFilter = THREE.NearestFilter

  constructor: (options) ->
    parameters =
      lights: true
      blending: THREE.NormalBlending
      transparent: true
      side: THREE.FrontSide
      shadowSide: THREE.FrontSide
      wireframe: false

      uniforms: _.extend
        visualizeTemperature:
          value: false
        visualizeHumidity:
          value: false
        blocksInformation:
          value: null
        blocksInformationSize:
          value: new THREE.Vector2 options.blocksInformationTexture.texture.image.width, options.blocksInformationTexture.texture.image.height
        materialData:
          value: options.materialsDataTexture
        materialDataSize:
          value: new THREE.Vector2 options.materialsDataTexture.image.width, options.materialsDataTexture.image.height
        tileset:
          value: @constructor.tilesetTexture
        tilesetSize:
          value: new THREE.Vector2 @constructor.tilesetTexture.image.width, @constructor.tilesetTexture.image.height
        worldSize:
          value: options.worldSizeVector
        blockTypesCount:
          value: _.keys(ProjectGaia.BlockTypes).length
        drawWater:
          value: false
        drawSolids:
          value: true
      ,
        ProjectGaia.Materials.getTimeUniforms()
      ,
        THREE.UniformsLib.lights

      defines: ProjectGaia.Materials.getTypeDefines()

      vertexShader: @constructor.vertexShader
      fragmentShader: @constructor.fragmentShader

    super parameters
    @options = options

  setWaterPass: (waterPass) ->
    @uniforms.drawWater.value = waterPass
    @uniforms.drawSolids.value = not waterPass

  update: (gameTime) ->
    # Update time.
    ProjectGaia.Materials.updateTimeUniforms @uniforms, gameTime

    # Set flipped blocks information texture.
    @uniforms.blocksInformation.value = @options.blocksInformationTexture.texture
