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
        drawWater:
          value: true
        drawSolids:
          value: true
        ,
          ProjectGaia.Materials.getTimeUniforms()

      defines: ProjectGaia.Materials.getTypeDefines()

      vertexShader: """
        #include <voxelworld_pars_vertex>
        void main() {
          bool discardInvisible = true;
          #include <voxelworld_blockinformation>
          #include <voxelworld_discardinvisible_vertex>
          #include <begin_vertex>
          #include <voxelworld_waterwaves_vertex>
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
    # Update time.
    ProjectGaia.Materials.updateTimeUniforms @uniforms, gameTime

    # Set flipped blocks information texture.
    @uniforms.blocksInformation.value = @options.blocksInformationTexture.texture
