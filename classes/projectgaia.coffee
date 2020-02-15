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
    ambientLight = new THREE.AmbientLight 0x606090
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
    directionalLight.position.set 30, 50, 40
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
    ProjectGaia.Materials.VegetationInformation.load @loadingManager
    ProjectGaia.VoxelWorld.load @loadingManager

  initialize: ->
    # Determine world size.
    model = ProjectGaia.VoxelWorld.environmentModel

    @worldSize =
      width: model.width
      height: model.height + 20
      depth: model.depth

    worldSizeVector = new THREE.Vector3 @worldSize.width, @worldSize.height, @worldSize.depth

    # Create ground plane.
    groundGeometry = new THREE.PlaneBufferGeometry(@worldSize.width + 100, @worldSize.depth + 100)
    groundMaterial = new THREE.MeshLambertMaterial color: 0x808080

    ground = new THREE.Mesh groundGeometry, groundMaterial
    ground.receiveShadow = true
    ground.rotation.x = -Math.PI / 2
    # @scene.add ground

    # Create main voxel world instance.
    @voxelWorld = new ProjectGaia.VoxelWorld @worldSize

    # Create materials data texture.
    @materialsDataTexture = new ProjectGaia.MaterialsDataTexture

    # Create vegetation models data texture.
    @vegetationDataTexture = new ProjectGaia.VegetationDataTexture

    # Create information textures.
    @blocksInformationTexture = new ProjectGaia.ComputedTexture
      renderer: @renderer
      initializationTexture: @voxelWorld.startingBlocksInformationTexture
      mapName: 'blocksInformation'

    @vegetationInformationTexture = new ProjectGaia.ComputedTexture
      renderer: @renderer
      mapName: 'vegetationInformation'
      width: @voxelWorld.startingBlocksInformationTexture.image.width
      height: @voxelWorld.startingBlocksInformationTexture.image.height

    # Create blocks information compute shader.
    @blocksInformationMaterial = new ProjectGaia.Materials.BlocksInformation
      materialsDataTexture: @materialsDataTexture
      blocksInformationTexture: @blocksInformationTexture
      vegetationInformationTexture: @vegetationInformationTexture
      worldSizeVector: worldSizeVector

    @blocksInformationTexture.setMaterial @blocksInformationMaterial

    # Create vegetation information compute shader.
    @vegetationInformationMaterial = new ProjectGaia.Materials.VegetationInformation
      materialsDataTexture: @materialsDataTexture
      vegetationDataTexture: @vegetationDataTexture
      blocksInformationTexture: @blocksInformationTexture
      vegetationInformationTexture: @vegetationInformationTexture
      worldSizeVector: worldSizeVector

    @vegetationInformationTexture.setMaterial @vegetationInformationMaterial

    # Create world rendering objects.
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
    @voxelMesh.position.set -@worldSize.width / 2, -5, -@worldSize.depth / 2
    @scene.add @voxelMesh

    # Create the camera.
    @camera = new THREE.PerspectiveCamera 45, window.innerWidth / window.innerHeight, 1, 400
    @camera.position.set 0, @worldSize.height, @worldSize.depth * 1.75

    # Create controls.
    @controls = new THREE.OrbitControls @camera, @renderer.domElement

    document.addEventListener 'keypress', (event) =>
      switch event.keyCode
        when 104
          @voxelWorldMaterial.uniforms.visualizeHumidity.value = not @voxelWorldMaterial.uniforms.visualizeHumidity.value

        when 116
          @voxelWorldMaterial.uniforms.visualizeTemperature.value = not @voxelWorldMaterial.uniforms.visualizeTemperature.value

    # Prepare time keeping.
    @simulationAccumulatedTime = 0

    @simulationGameTime =
      totalGameTime: 0
      elapsedGameTime: 0.2

    @vegetationUpdateGameTime =
      totalGameTime: 0
      elapsedGameTime: 0.2

    # Start vegetation time out of phase with simulation update.
    @vegetationAccumulatedTime = @vegetationUpdateGameTime.elapsedGameTime / 2

    # We have completed initialization.
    @initialized = true

  update: (gameTime) ->
    return unless @initialized

    # Update vegetation in between simulation updates.
    @vegetationAccumulatedTime += gameTime.elapsedGameTime

    if @vegetationAccumulatedTime > @vegetationUpdateGameTime.elapsedGameTime
      @vegetationAccumulatedTime -= @vegetationUpdateGameTime.elapsedGameTime
      @vegetationUpdateGameTime.totalGameTime += @vegetationUpdateGameTime.elapsedGameTime

      @vegetationInformationMaterial.update @vegetationUpdateGameTime
      @vegetationInformationTexture.update @vegetationUpdateGameTime

    # Update blocks simulation.
    @simulationAccumulatedTime += gameTime.elapsedGameTime

    if @simulationAccumulatedTime > @simulationGameTime.elapsedGameTime
      @simulationAccumulatedTime -= @simulationGameTime.elapsedGameTime
      @simulationGameTime.totalGameTime += @simulationGameTime.elapsedGameTime

      @blocksInformationMaterial.update @simulationGameTime
      @blocksInformationTexture.update @simulationGameTime
      @voxelWorldMaterial.update @simulationGameTime
      @voxelWorldDepthMaterial.update @simulationGameTime

    # Update controls on every frame.
    @controls.update gameTime

  draw: (gameTime) ->
    return unless @initialized

    @renderer.setRenderTarget null
    @renderer.render @scene, @camera

window.ProjectGaia = ProjectGaia
