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
        materialDataSize:
          value: new THREE.Vector2 options.materialsDataTexture.image.width, options.materialsDataTexture.image.height
        vegetationInformation:
          value: options.vegetationInformationTexture.texture
        vegetationInformationSize:
          value: new THREE.Vector2 options.vegetationInformationTexture.texture.image.width, options.vegetationInformationTexture.texture.image.height
        worldSize:
          value: options.worldSizeVector
        blockTypesCount:
          value: _.keys(ProjectGaia.BlockTypes).length
      ,
        ProjectGaia.Materials.getTimeUniforms()
      ,
        ProjectGaia.Materials.getRandomUniforms()

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
