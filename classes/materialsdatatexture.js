// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  ProjectGaia.MaterialsDataTexture = (function(superClass) {
    extend(MaterialsDataTexture, superClass);

    function MaterialsDataTexture() {
      var blockMaterial, blockMaterialIndex, blockMaterialProperties, blockType, blockTypeIndex, blockTypesCount, color, dataArray, height, humidity, i, j, materialMapping, paletteRow, pixelOffset, ref, ref1, temperature, width, x, y;
      blockTypesCount = _.keys(ProjectGaia.BlockTypes).length;
      width = 32;
      height = blockTypesCount + 1;
      dataArray = new Uint8Array(width * height * 3);
      ref = ProjectGaia.BlockTypes;
      for (blockType in ref) {
        blockTypeIndex = ref[blockType];
        materialMapping = ProjectGaia.VoxelWorld.BlockMaterialMappings[blockTypeIndex];
        y = blockTypeIndex;
        for (temperature = i = 0; i <= 4; temperature = ++i) {
          for (humidity = j = 0; j <= 4; humidity = ++j) {
            x = temperature + humidity * 5;
            pixelOffset = (x + y * width) * 3;
            dataArray[pixelOffset] = materialMapping.getBlockMaterialForProperties(temperature, humidity);
          }
        }
      }
      paletteRow = blockTypesCount;
      ref1 = ProjectGaia.BlockMaterials;
      for (blockMaterial in ref1) {
        blockMaterialIndex = ref1[blockMaterial];
        if (!(blockMaterialProperties = ProjectGaia.VoxelWorld.BlockMaterialProperties[blockMaterialIndex])) {
          continue;
        }
        pixelOffset = (blockMaterialIndex + paletteRow * width) * 3;
        color = blockMaterialProperties.color;
        dataArray[pixelOffset] = color.r * 255;
        dataArray[pixelOffset + 1] = color.g * 255;
        dataArray[pixelOffset + 2] = color.b * 255;
      }
      MaterialsDataTexture.__super__.constructor.call(this, dataArray, width, height, THREE.RGBFormat);
    }

    return MaterialsDataTexture;

  })(THREE.DataTexture);

}).call(this);

//# sourceMappingURL=materialsdatatexture.js.map
