// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  ProjectGaia.Materials.VoxelWorld.Depth = (function(superClass) {
    extend(Depth, superClass);

    function Depth(options) {
      var parameters;
      parameters = {
        blending: THREE.NoBlending,
        uniforms: _.extend({
          blocksInformation: {
            value: null
          },
          blocksInformationSize: {
            value: new THREE.Vector2(options.blocksInformationTexture.texture.image.width, options.blocksInformationTexture.texture.image.height)
          },
          worldSize: {
            value: options.worldSizeVector
          }
        }),
        vertexShader: "#include <voxelworld_pars_vertex>\nvoid main() {\n  #include <voxelworld_discardinvisible_vertex>\n  #include <begin_vertex>\n  #include <project_vertex>\n  #include <worldpos_vertex>\n}",
        fragmentShader: "#include <packing>\nvoid main() {gl_FragColor = packDepthToRGBA(gl_FragCoord.z);}"
      };
      Depth.__super__.constructor.call(this, parameters);
      this.options = options;
    }

    Depth.prototype.update = function(gameTime) {
      return this.uniforms.blocksInformation.value = this.options.blocksInformationTexture.texture;
    };

    return Depth;

  })(THREE.ShaderMaterial);

}).call(this);

//# sourceMappingURL=voxelworld-depth.js.map