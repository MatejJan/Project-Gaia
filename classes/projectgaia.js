// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var ProjectGaia;

  ProjectGaia = (function() {
    function ProjectGaia() {
      var ambientLight, directionalLight, worldSize;
      this.renderer = new THREE.WebGLRenderer;
      this.renderer.setSize(window.innerWidth, window.innerHeight);
      document.body.appendChild(this.renderer.domElement);
      this.scene = new THREE.Scene;
      ambientLight = new THREE.AmbientLight(0x404060);
      this.scene.add(ambientLight);
      directionalLight = new THREE.DirectionalLight(0xffffdd, 0.5);
      directionalLight.position.set(1, 5, 2);
      this.scene.add(directionalLight);
      worldSize = {
        width: 32,
        height: 32,
        depth: 32
      };
      this.voxelWorld = new ProjectGaia.VoxelWorld(worldSize);
      this.voxelMesh = new ProjectGaia.VoxelMesh(_.extend({
        world: this.voxelWorld
      }, worldSize));
      this.voxelMesh.position.set(-worldSize.width / 2, -worldSize.height / 2, worldSize.depth / 2);
      this.scene.add(this.voxelMesh);
      this.camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 1, 400);
      this.camera.position.z = worldSize.depth * 2;
      this.controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
    }

    ProjectGaia.prototype.update = function(gameTime) {
      return this.controls.update();
    };

    ProjectGaia.prototype.draw = function(gameTime) {
      return this.renderer.render(this.scene, this.camera);
    };

    return ProjectGaia;

  })();

  window.ProjectGaia = ProjectGaia;

}).call(this);

//# sourceMappingURL=projectgaia.js.map
