'use strict'

class ProjectGaia.VoxelMesh extends THREE.Mesh
  constructor: (@options) ->
    width = @options.width
    height = @options.height
    depth = @options.depth
    blocksCount = width * height * depth

    verticesPerSide = 4
    verticesPerBlock = verticesPerSide * 6

    indicesPerSide = 6
    indicesPerBlock = indicesPerSide * 6

    vertexArraysLength = blocksCount * verticesPerBlock * 3
    positionsArray = new Float32Array vertexArraysLength
    normalsArray = new Float32Array vertexArraysLength
    blockCoordinatesArray = new Uint8Array vertexArraysLength

    for z in [0...depth]
      for y in [0...height]
        for x in [0...width]
          blockOffset = @options.world.getBlockIndexForCoordinates(x, y, z) * verticesPerBlock * 3

          for side in [0..5]
            for j in [0..1]
              for i in [0..1]
                index = blockOffset + (i + j * 2 + side * 4) * 3

                @createVertexForSide positionsArray, index, side, x, y, z, i, j

                normal = ProjectGaia.Sides.Normals[side]
                normalsArray[index] = normal.x
                normalsArray[index + 1] = normal.y
                normalsArray[index + 2] = normal.z

                blockCoordinatesArray[index] = x
                blockCoordinatesArray[index + 1] = y
                blockCoordinatesArray[index + 2] = z

    indicesArrayLength = blocksCount * indicesPerBlock
    indicesArray = new Uint32Array indicesArrayLength

    for z in [0...depth]
      for y in [0...height]
        for x in [0...width]
          blockIndex = @options.world.getBlockIndexForCoordinates x, y, z
          blockOffset = blockIndex * indicesPerBlock

          for side in [0..5]
            index = blockOffset + side * indicesPerSide
            verticesOffset = blockIndex * verticesPerBlock + side * verticesPerSide

            indicesArray[index] = verticesOffset
            indicesArray[index + 1] = verticesOffset + 1
            indicesArray[index + 2] = verticesOffset + 3
            indicesArray[index + 3] = verticesOffset
            indicesArray[index + 4] = verticesOffset + 3
            indicesArray[index + 5] = verticesOffset + 2

    geometry = new THREE.BufferGeometry()

    positionAttribute = new THREE.BufferAttribute positionsArray, 3
    normalAttribute = new THREE.BufferAttribute normalsArray, 3
    blockCoordinatesAttribute = new THREE.BufferAttribute blockCoordinatesArray, 3

    geometry.setAttribute "position", positionAttribute
    geometry.setAttribute "normal", normalAttribute
    geometry.setAttribute "blockCoordinates", blockCoordinatesAttribute

    indicesAttribute = new THREE.BufferAttribute indicesArray, 1
    geometry.setIndex indicesAttribute

    super geometry, @options.material

  createVertexForSide: (array, index, side, x, y, z, i, j) ->
    rx = x
    ry = y
    rz = z

    switch side
      when ProjectGaia.Sides.Right
        rx++
        ry += j
        rz -= i
      when ProjectGaia.Sides.Left
        ry += j
        rz -= 1 - i
      when ProjectGaia.Sides.Up
        rx += i
        ry++
        rz -= j
      when ProjectGaia.Sides.Down
        rx += i
        rz += j - 1
      when ProjectGaia.Sides.Forward
        rx += 1 - i
        ry += j
        rz--
      when ProjectGaia.Sides.Back
        rx += i
        ry += j

    array[index] = rx
    array[index + 1] = ry
    array[index + 2] = rz
