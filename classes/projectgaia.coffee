'use strict'

class ProjectGaia
  constructor: ->
    # Create the renderer.
    @renderer = new THREE.WebGLRenderer
    @renderer.setSize window.innerWidth, window.innerHeight
    @renderer.autoClear = false
    @renderer.shadowMap.enabled = true
    @renderer.shadowMap.autoUpdate = false
    @renderer.shadowMap.type = THREE.PCFSoftShadowMap
    @renderer.setClearColor new THREE.Color(0.05, 0.05, 0.1), 1
    document.body.appendChild @renderer.domElement

    # Create the scene.
    @scene = new THREE.Scene

    # Create lighting.
    @sky = new THREE.HemisphereLight
    @scene.add @sky

    # Define ambient light colors (12AM, 3, 6, 9, 12PM, 3, 6, 9, 12AM)
    createSkyColors = (hexValues) =>
      for hexValue in hexValues
        hsl = new THREE.Color(hexValue).getHSL()
        new THREE.Color().setHSL hsl.h, hsl.s * 1.2, hsl.l * 1.2

    @skyColors =
      top: createSkyColors [0x101b31, 0x101b31, 0x192c4c, 0x285e9a, 0x4471b2, 0x375696, 0x6f7d9a, 0x474b61, 0x101b31]
      bottom: createSkyColors [0x213867, 0x213867, 0xb99b84, 0xb9bdc3, 0xb5d7f3, 0xc3dcf8, 0xf1dcb3, 0xaa6748, 0x213867]

    # Create sunlight.
    @sun = new THREE.DirectionalLight 0, 1
    @sun.castShadow = true
    shadowCameraHalfSize = 80
    @sun.shadow.camera.left = -shadowCameraHalfSize
    @sun.shadow.camera.right = shadowCameraHalfSize
    @sun.shadow.camera.top = shadowCameraHalfSize
    @sun.shadow.camera.bottom = -shadowCameraHalfSize
    @sun.shadow.camera.near = 10
    @sun.shadow.camera.far = 200
    @sun.shadow.mapSize.width = 4096
    @sun.shadow.mapSize.height = 4096
    @sun.shadow.bias = -0.001
    @scene.add @sun

    @sunColors = for hexValue in [0, 0, 0xaf855e, 0xffffca, 0xffffca, 0xffffca, 0xeec137, 0xd86726, 0]
      new THREE.Color hexValue

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
    @voxelMesh.position.set -@worldSize.width / 2, -10, -@worldSize.depth / 2
    @scene.add @voxelMesh

    # Create the camera.
    @camera = new THREE.PerspectiveCamera 45, window.innerWidth / window.innerHeight, 1, 400
    @camera.position.set -@worldSize.depth * 1.2, @worldSize.height, @worldSize.depth * 1.2

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

    @voxelWorldMaterial.update gameTime
    @voxelWorldDepthMaterial.update gameTime

    # Update controls on every frame.
    @controls.update gameTime

  draw: (gameTime) ->
    return unless @initialized

    # Update time of day.
    timeOfDay = (0.35 + gameTime.totalGameTime * 0.003) % 1
    
    # Update sky colors.
    skyColorIndex = Math.floor(timeOfDay * 8)
    skyColorProgress = (timeOfDay * 8) % 1

    @sky.color.copy(@skyColors.top[skyColorIndex]).lerp @skyColors.top[skyColorIndex + 1], skyColorProgress
    @sky.groundColor.copy(@skyColors.bottom[skyColorIndex]).lerp @skyColors.bottom[skyColorIndex + 1], skyColorProgress

    # Update sun position.
    sunAngle = -Math.PI / 2 + timeOfDay * Math.PI * 2
    sunDistance = (Math.sqrt(@worldSize.width ** 2, @worldSize.height ** 2) + @sun.shadow.camera.near) * 1.1
    @sun.position.set Math.cos(sunAngle) * sunDistance, Math.sin(sunAngle) * sunDistance, sunDistance * 0.5
    @sun.color.copy(@sunColors[skyColorIndex]).lerp @sunColors[skyColorIndex + 1], skyColorProgress

    @renderer.setRenderTarget null
    @renderer.clear()

    @voxelWorldMaterial.setWaterPass false
    @renderer.shadowMap.needsUpdate = true
    @renderer.render @scene, @camera

    @voxelWorldMaterial.setWaterPass true
    @renderer.render @scene, @camera

window.ProjectGaia = ProjectGaia
