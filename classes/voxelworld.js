// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  ProjectGaia.VoxelWorld = (function() {
    var Materials, Types, Vegetation, colorFromRGB, ref, vegetationTypeIndex, vegetationTypeName;

    Types = ProjectGaia.BlockTypes;

    Materials = ProjectGaia.BlockMaterials;

    VoxelWorld.BlockMaterialMappings = [new ProjectGaia.BlockMaterialMapping([[Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty], [Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty], [Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty], [Materials.Cloud, Materials.Cloud, Materials.Cloud, Materials.Cloud, Materials.Cloud], [Materials.Rain, Materials.Rain, Materials.Rain, Materials.Rain, Materials.Rain]]), new ProjectGaia.BlockMaterialMapping([[Materials.Rock, Materials.Rock, Materials.Gravel, Materials.Gravel, Materials.Sand], [Materials.Rock, Materials.Soil, Materials.Soil, Materials.Gravel, Materials.Sand], [Materials.Snow, Materials.Soil, Materials.Soil, Materials.Soil, Materials.Sand], [Materials.FrozenRock, Materials.Soil, Materials.Soil, Materials.Mud, Materials.Mud], [Materials.FrozenRock, Materials.Snow, Materials.Mud, Materials.Mud, Materials.Mud]]), new ProjectGaia.BlockMaterialMapping([[Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty, Materials.Empty], [Materials.Ice, Materials.Water, Materials.Water, Materials.Water, Materials.Steam], [Materials.Ice, Materials.Water, Materials.Water, Materials.Water, Materials.Steam], [Materials.Ice, Materials.Water, Materials.Swamp, Materials.Swamp, Materials.Steam], [Materials.Ice, Materials.Water, Materials.Swamp, Materials.Swamp, Materials.Steam]])];

    colorFromRGB = function(r, g, b) {
      return new THREE.Color().setIntegerRGB(r, g, b);
    };

    VoxelWorld.BlockMaterialProperties = [];

    VoxelWorld.BlockMaterialProperties[Materials.Cloud] = {
      blockType: Types.Water,
      color: colorFromRGB(188, 212, 224)
    };

    VoxelWorld.BlockMaterialProperties[Materials.Rain] = {
      blockType: Types.Water,
      color: colorFromRGB(59, 128, 150)
    };

    VoxelWorld.BlockMaterialProperties[Materials.Rock] = {
      blockType: Types.Earth,
      color: colorFromRGB(78, 78, 86)
    };

    VoxelWorld.BlockMaterialProperties[Materials.FrozenRock] = {
      blockType: Types.Earth,
      color: colorFromRGB(130, 173, 179)
    };

    VoxelWorld.BlockMaterialProperties[Materials.Soil] = {
      blockType: Types.Earth,
      color: colorFromRGB(157, 107, 80)
    };

    VoxelWorld.BlockMaterialProperties[Materials.Snow] = {
      blockType: Types.Earth,
      color: colorFromRGB(242, 238, 204)
    };

    VoxelWorld.BlockMaterialProperties[Materials.Gravel] = {
      blockType: Types.Earth,
      color: colorFromRGB(122, 113, 89)
    };

    VoxelWorld.BlockMaterialProperties[Materials.Sand] = {
      blockType: Types.Earth,
      color: colorFromRGB(231, 210, 130)
    };

    VoxelWorld.BlockMaterialProperties[Materials.Mud] = {
      blockType: Types.Earth,
      color: colorFromRGB(108, 74, 74)
    };

    VoxelWorld.BlockMaterialProperties[Materials.Ice] = {
      blockType: Types.Water,
      color: colorFromRGB(188, 212, 223)
    };

    VoxelWorld.BlockMaterialProperties[Materials.Water] = {
      blockType: Types.Water,
      color: colorFromRGB(59, 128, 149)
    };

    VoxelWorld.BlockMaterialProperties[Materials.Swamp] = {
      blockType: Types.Water,
      color: colorFromRGB(75, 89, 61)
    };

    VoxelWorld.BlockMaterialProperties[Materials.Steam] = {
      blockType: Types.Water,
      color: colorFromRGB(228, 216, 202)
    };

    VoxelWorld.registerCustomMaterial = function(color) {
      var materialIndex, materialName;
      materialIndex = _.keys(ProjectGaia.BlockMaterials).length;
      materialName = "Unknown" + materialIndex;
      ProjectGaia.BlockMaterials[materialName] = materialIndex;
      this.BlockMaterialProperties[materialIndex] = {
        blockType: Types.Custom,
        color: color
      };
      return materialIndex;
    };

    VoxelWorld.getMaterialIndexForColor = function(colorOrR, g, b) {
      var color, materialIndex, r;
      if (colorOrR instanceof THREE.Color) {
        color = colorOrR;
      } else {
        r = colorOrR;
        color = colorFromRGB(r, g, b);
      }
      materialIndex = _.findIndex(this.BlockMaterialProperties, (function(_this) {
        return function(blockMaterialProperties) {
          return blockMaterialProperties != null ? blockMaterialProperties.color.equals(color) : void 0;
        };
      })(this));
      if (materialIndex >= 0) {
        return materialIndex;
      } else {
        return null;
      }
    };

    VoxelWorld.getPropertiesForMaterial = function(blockMaterial) {
      var blockMaterialMapping, blockType, humidity, i, j, k, len, ref, temperature;
      ref = this.BlockMaterialMappings;
      for (blockType = i = 0, len = ref.length; i < len; blockType = ++i) {
        blockMaterialMapping = ref[blockType];
        for (temperature = j = 0; j <= 4; temperature = ++j) {
          for (humidity = k = 0; k <= 4; humidity = ++k) {
            if (blockMaterialMapping.getBlockMaterialForProperties(temperature, humidity) === blockMaterial) {
              return {
                temperature: temperature,
                humidity: humidity
              };
            }
          }
        }
      }
      return null;
    };

    Vegetation = ProjectGaia.VegetationTypes;

    VoxelWorld.VegetationProperties = [];

    ref = ProjectGaia.VegetationTypes;
    for (vegetationTypeName in ref) {
      vegetationTypeIndex = ref[vegetationTypeName];
      if (vegetationTypeIndex) {
        VoxelWorld.VegetationProperties[vegetationTypeIndex] = {
          modelName: _.kebabCase(vegetationTypeName)
        };
      }
    }

    VoxelWorld.load = function(loadingManager) {
      var environmentNames, i, len, ref1, results, urlParameters, vegetationProperties, worldIndex;
      environmentNames = ['32x32x32-materials', '40x40x30-island-snow-rock', '40x40x30-island-soil-mud', '40x40x39-tunnel', '40x40x40-rock-canyon-sand-soil', '50x50x40-island-soil-sand-mud', '64x64x64-test', '120x120x60-big'];
      urlParameters = new URLSearchParams(window.location.search);
      worldIndex = urlParameters.get('world') || 0;
      this.environmentModel = new ProjectGaia.VoxelModel({
        url: "content/environments/" + environmentNames[worldIndex] + ".vox",
        loadingManager: loadingManager
      });
      this.vegetationModels = [];
      ref1 = this.VegetationProperties;
      results = [];
      for (vegetationTypeIndex = i = 0, len = ref1.length; i < len; vegetationTypeIndex = ++i) {
        vegetationProperties = ref1[vegetationTypeIndex];
        if (vegetationTypeIndex) {
          results.push(this.vegetationModels[vegetationTypeIndex] = new ProjectGaia.VoxelModel({
            url: "content/vegetation/" + vegetationProperties.modelName + ".vox",
            loadingManager: loadingManager
          }));
        }
      }
      return results;
    };

    function VoxelWorld(options) {
      var block, blocksInformationArray, dataHeight, dataWidth, i, index, j, k, materialProperties, ref1, ref2, ref3, x, y, z;
      this.options = options;
      dataWidth = 1024;
      dataHeight = 1024;
      blocksInformationArray = new Uint8Array(dataWidth * dataHeight * 4);
      blocksInformationArray.fill(255);
      for (z = i = 0, ref1 = this.options.depth; 0 <= ref1 ? i < ref1 : i > ref1; z = 0 <= ref1 ? ++i : --i) {
        for (y = j = 0, ref2 = this.options.height; 0 <= ref2 ? j < ref2 : j > ref2; y = 0 <= ref2 ? ++j : --j) {
          for (x = k = 0, ref3 = this.options.width; 0 <= ref3 ? k < ref3 : k > ref3; x = 0 <= ref3 ? ++k : --k) {
            index = this.getBlockIndexForCoordinates(x, y, z) * 4;
            block = this.constructor.environmentModel.blocks[x][y][z];
            materialProperties = this.constructor.getPropertiesForMaterial(block.material);
            blocksInformationArray[index] = block.type;
            blocksInformationArray[index + 1] = (materialProperties != null ? materialProperties.temperature : void 0) || 0;
            blocksInformationArray[index + 2] = (materialProperties != null ? materialProperties.humidity : void 0) || 0;
            blocksInformationArray[index + 3] = block.material;
          }
        }
      }
      this.startingBlocksInformationTexture = new THREE.DataTexture(blocksInformationArray, dataWidth, dataHeight, THREE.RGBAFormat);
    }

    VoxelWorld.prototype.getBlockIndexForCoordinates = function(x, y, z) {
      return x + y * this.options.width + z * this.options.width * this.options.height;
    };

    return VoxelWorld;

  })();

}).call(this);

//# sourceMappingURL=voxelworld.js.map
