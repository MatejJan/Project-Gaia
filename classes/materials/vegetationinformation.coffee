'use strict'

class ProjectGaia.Materials.VegetationInformation extends THREE.RawShaderMaterial
  @load: (loadingManager) ->
    new THREE.FileLoader(loadingManager).load 'classes/materials/vegetationinformationfragmentshader.glsl', (@fragmentShader) =>

  constructor: (options) ->
    parameters =
      blending: THREE.NoBlending

      uniforms: _.extend
        blocksInformation:
          value: options.blocksInformationTexture.texture
        blocksInformationSize:
          value: new THREE.Vector2 options.blocksInformationTexture.texture.image.width, options.blocksInformationTexture.texture.image.height
        vegetationInformation:
          value: options.vegetationInformationTexture.texture
        vegetationInformationSize:
          value: new THREE.Vector2 options.vegetationInformationTexture.texture.image.width, options.vegetationInformationTexture.texture.image.height
        vegetationData:
          value: options.vegetationDataTexture
        vegetationDataSize:
          value: new THREE.Vector2 options.vegetationDataTexture.image.width, options.vegetationDataTexture.image.height
        worldSize:
          value: options.worldSizeVector
        blockTypesCount:
          value: _.keys(ProjectGaia.BlockTypes).length
      ,
        ProjectGaia.Materials.getTimeUniforms()
      ,
        ProjectGaia.Materials.getRandomUniforms()

      defines: ProjectGaia.Materials.getTypeDefines()

      vertexShader: ProjectGaia.ComputedTexture.vertexShader
      fragmentShader: @constructor.fragmentShader

    super parameters
    @options = options

  update: (gameTime) ->
    # Update time.
    ProjectGaia.Materials.updateTimeUniforms @uniforms, gameTime
    ProjectGaia.Materials.updateRandomUniforms @uniforms

    # Set flipped information textures.
    @uniforms.blocksInformation.value = @options.blocksInformationTexture.texture
    @uniforms.vegetationInformation.value = @options.vegetationInformationTexture.texture

    @needsUpdate = true
