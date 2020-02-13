'use strict'

class ProjectGaia.ComputedTexture
  @vertexShader: """
attribute vec3 position;
attribute vec2 uv;

varying vec2 vUv;

void main() {
  gl_Position = vec4(position, 1.0);
  vUv = uv;
}
"""

  constructor: (@options) ->
    @renderTargets = []

    image = @options.initializationTexture?.image

    for i in [0..1]
      renderTarget = new THREE.WebGLRenderTarget image?.width or @options.width, image?.height or @options.height,
        minFilter: THREE.NearestFilter
        magFilter: THREE.NearestFilter

      @renderTargets.push renderTarget

    @quad = new THREE.Mesh new THREE.PlaneBufferGeometry(2, 2)
    @quad.position.set 0.5, 0.5, -1

    @scene = new THREE.Scene()
    @scene.add @quad

    @camera = new THREE.OrthographicCamera 0, 1, 0, 1, 0.5, 1.5

    if @options.initializationTexture
      # Initialize the render target.
      initializationMaterial = new @constructor.InitializationMaterial
        map: @options.initializationTexture

      @quad.material = initializationMaterial

      @options.renderer.setRenderTarget @renderTargets[1]
      @options.renderer.render @scene, @camera

    # Set the update material.
    @quad.material = @options.material
    @texture = @renderTargets[1].texture

  setMaterial: (material) ->
    @quad.material = material

  update: (gameTime) ->
    # Flip render targets.
    @renderTargets = [@renderTargets[1], @renderTargets[0]]

    # Set first render target as input texture on the material.
    @quad.material.uniforms[@options.mapName].value = @renderTargets[0].texture

    # Render to the second render target.
    @options.renderer.setRenderTarget @renderTargets[1]
    @options.renderer.render @scene, @camera

    # Update texture pointer to the just-rendered target.
    @texture = @renderTargets[1].texture

  class @InitializationMaterial extends THREE.RawShaderMaterial
    constructor: (options) ->
      super
        blending: THREE.NoBlending

        uniforms: _.extend
          map:
            value: options.map

        vertexShader: ProjectGaia.ComputedTexture.vertexShader
        fragmentShader: """
precision mediump float;

uniform sampler2D map;
varying vec2 vUv;

void main() {
  gl_FragColor = texture2D(map, vUv);
}

"""
        @map = options.map
        @needsUpdate = true
