'use strict'

class ProjectGaia.Materials.VoxelWorld.Depth extends THREE.ShaderMaterial
  constructor: (options) ->
    parameters =
      blending: THREE.NoBlending

      uniforms: _.extend
        blocksInformation:
          value: null
        blocksInformationSize:
          value: new THREE.Vector2 options.blocksInformationTexture.texture.image.width, options.blocksInformationTexture.texture.image.height
        worldSize:
          value: options.worldSizeVector

      vertexShader: """
        #include <voxelworld_pars_vertex>
        void main() {
          #include <voxelworld_discardinvisible_vertex>
          #include <begin_vertex>
          #include <project_vertex>
          #include <worldpos_vertex>
        }
      """

      fragmentShader: """
        #include <packing>
        void main() {gl_FragColor = packDepthToRGBA(gl_FragCoord.z);}
      """

    super parameters
    @options = options

  update: (gameTime) ->
    # Set flipped blocks information texture.
    @uniforms.blocksInformation.value = @options.blocksInformationTexture.texture
