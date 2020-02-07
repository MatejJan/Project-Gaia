'use strict'

class ProjectGaia
  constructor: ->
    # Create the renderer.
    @renderer = new THREE.WebGLRenderer
    @renderer.setSize window.innerWidth, window.innerHeight
    document.body.appendChild @renderer.domElement

    # Create the scene.
    @scene = new THREE.Scene

    ambientLight = new THREE.AmbientLight 0x404060
    @scene.add ambientLight

    directionalLight = new THREE.DirectionalLight 0xffffdd, 0.5
    directionalLight.position.set 1, 5, 2
    @scene.add directionalLight

    worldSize =
      width: 32
      height: 32
      depth: 32

    @voxelWorld = new ProjectGaia.VoxelWorld worldSize

    @voxelMesh = new ProjectGaia.VoxelMesh _.extend
      world: @voxelWorld
    ,
      worldSize

    @voxelMesh.position.set -worldSize.width / 2, -worldSize.height / 2, worldSize.depth / 2
    @scene.add @voxelMesh

    # Create the camera.
    @camera = new THREE.PerspectiveCamera 60, window.innerWidth / window.innerHeight, 1, 400
    @camera.position.z = worldSize.depth * 2

    @controls = new THREE.OrbitControls @camera, @renderer.domElement

  update: (gameTime) ->
    @controls.update()

  draw: (gameTime) ->
    @renderer.render @scene, @camera

window.ProjectGaia = ProjectGaia
