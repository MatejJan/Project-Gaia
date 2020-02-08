'use strict'

projectGaia = new ProjectGaia

totalTime = 0
lastFrameTime = null

fpsCounter = 0
fpsCounterTime = 0

gameLoop = (timestamp) ->
  lastFrameTime ?= timestamp
  elapsedTime = (timestamp - lastFrameTime) / 1000
  lastFrameTime = timestamp

  # Bound elapsed time to 1 FPS.
  elapsedTime = Math.min 1, elapsedTime

  # Measure FPS.
  fpsCounter++
  fpsCounterTime += elapsedTime

  if fpsCounterTime > 1
    console.log "Running at #{fpsCounter} FPS"

    fpsCounter = 0
    fpsCounterTime -= 1

  totalTime += elapsedTime

  gameTime =
    elapsedGameTime: elapsedTime
    totalGameTime: totalTime

  projectGaia.update gameTime
  projectGaia.draw gameTime

  requestAnimationFrame gameLoop

requestAnimationFrame gameLoop
