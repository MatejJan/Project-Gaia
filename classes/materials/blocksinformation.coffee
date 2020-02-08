'use strict'

class ProjectGaia.Materials.BlocksInformation extends THREE.RawShaderMaterial
  @load: (loadingManager) ->
    new THREE.FileLoader(loadingManager).load 'classes/materials/blocksinformationfragmentshader.glsl', (@fragmentShader) =>

  constructor: (options) ->
    parameters =
      blending: THREE.NoBlending

      uniforms: _.extend
        blocksInformation:
          value: options.blocksInformationTexture.texture
        blocksInformationSize:
          value: new THREE.Vector2 options.blocksInformationTexture.texture.image.width, options.blocksInformationTexture.texture.image.height
        materialData:
          value: options.materialsDataTexture
        worldSize:
          value: options.worldSizeVector
        blockTypesCount:
          value: _.keys(ProjectGaia.BlockTypes).length
      ,
        ProjectGaia.Materials.getTimeUniforms()

      vertexShader: ProjectGaia.ComputedTexture.vertexShader
      fragmentShader: @constructor.fragmentShader

    super parameters
    @options = options

  update: (gameTime) ->
    # Update time.
    ProjectGaia.Materials.updateTimeUniforms @uniforms, gameTime

    # Set flipped blocks information texture.
    @uniforms.blocksInformation.value = @options.blocksInformationTexture.texture

    @needsUpdate = true
