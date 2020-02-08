'use strict'

class ProjectGaia
  constructor: ->
    # Create the renderer.
    @renderer = new THREE.WebGLRenderer
    @renderer.setSize window.innerWidth, window.innerHeight
    @renderer.shadowMap.enabled = true
    @renderer.shadowMap.type = THREE.PCFSoftShadowMap
    @renderer.setClearColor new THREE.Color(0.05, 0.05, 0.1), 1
    document.body.appendChild @renderer.domElement

    # Create the scene.
    @scene = new THREE.Scene

    # Create lighting.
    ambientLight = new THREE.AmbientLight 0x404060
    @scene.add ambientLight

    directionalLight = new THREE.DirectionalLight 0xffffdd, 1
    directionalLight.castShadow = true
    shadowCameraHalfSize = 50
    directionalLight.shadow.camera.left = -shadowCameraHalfSize
    directionalLight.shadow.camera.right = shadowCameraHalfSize
    directionalLight.shadow.camera.top = shadowCameraHalfSize
    directionalLight.shadow.camera.bottom = -shadowCameraHalfSize
    directionalLight.shadow.camera.near = 10
    directionalLight.shadow.camera.far = 150
    directionalLight.shadow.mapSize.width = 4096
    directionalLight.shadow.mapSize.height = 4096
    directionalLight.shadow.bias = -0.001
    directionalLight.position.set 10, 50, 20
    @scene.add directionalLight

    # Create loading manager
    @loadingManager = new THREE.LoadingManager =>
      console.log "Loading finished!"
      @initialize()
    ,
    (url, itemsLoaded, itemsTotal) =>
          console.log "Loaded #{itemsLoaded} of #{itemsTotal}"
    ,
    (url) =>
          console.log "Loading error with", url

    # Load assets.
    ProjectGaia.Materials.VoxelWorld.load @loadingManager
    ProjectGaia.Materials.BlocksInformation.load @loadingManager

  initialize: ->
    sideLength = 32
    
    @worldSize =
      width: sideLength
      height: sideLength
      depth: sideLength

    groundGeometry = new THREE.PlaneBufferGeometry(@worldSize.width + 100, @worldSize.depth + 100)
    groundMaterial = new THREE.MeshLambertMaterial color: 0x808080

    ground = new THREE.Mesh groundGeometry, groundMaterial
    ground.receiveShadow = true
    ground.position.y = -@worldSize.height / 2
    ground.rotation.x = -Math.PI / 2
    @scene.add ground

    worldSizeVector = new THREE.Vector3 @worldSize.width, @worldSize.height, @worldSize.depth

    @voxelWorld = new ProjectGaia.VoxelWorld @worldSize

    @materialsDataTexture = new ProjectGaia.MaterialsDataTexture

    @blocksInformationTexture = new ProjectGaia.ComputedTexture
      renderer: @renderer
      initializationTexture: @voxelWorld.startingBlocksInformationTexture
      mapName: 'blocksInformation'

    @blocksInformationMaterial = new ProjectGaia.Materials.BlocksInformation
      materialsDataTexture: @materialsDataTexture
      blocksInformationTexture: @blocksInformationTexture
      worldSizeVector: worldSizeVector

    @blocksInformationTexture.setMaterial @blocksInformationMaterial

    @voxelWorldMaterial = new ProjectGaia.Materials.VoxelWorld
      materialsDataTexture: @materialsDataTexture
      blocksInformationTexture: @blocksInformationTexture
      worldSizeVector: worldSizeVector

    @voxelWorldDepthMaterial = new ProjectGaia.Materials.VoxelWorld.Depth
      blocksInformationTexture: @blocksInformationTexture
      worldSizeVector: worldSizeVector

    @voxelMesh = new ProjectGaia.VoxelMesh _.extend
      world: @voxelWorld
      material: @voxelWorldMaterial
    ,
      @worldSize

    @voxelMesh.castShadow = true
    @voxelMesh.receiveShadow = true
    @voxelMesh.customDepthMaterial = @voxelWorldDepthMaterial
    @voxelMesh.position.set -@worldSize.width / 2, -@worldSize.height / 2, -@worldSize.depth / 2
    @scene.add @voxelMesh

    # Create the camera.
    @camera = new THREE.PerspectiveCamera 60, window.innerWidth / window.innerHeight, 1, 400
    @camera.position.z = @worldSize.depth * 2

    @controls = new THREE.OrbitControls @camera, @renderer.domElement

    @initialized = true

  update: (gameTime) ->
    return unless @initialized

    @blocksInformationMaterial.update gameTime
    @blocksInformationTexture.update gameTime
    @voxelWorldMaterial.update gameTime
    @voxelWorldDepthMaterial.update gameTime
    @controls.update gameTime

  draw: (gameTime) ->
    return unless @initialized

    @renderer.setRenderTarget null
    @renderer.render @scene, @camera

window.ProjectGaia = ProjectGaia
