'use strict'

projectGaia = new ProjectGaia

totalTime = 0
lastFrameTime = null

fpsCounter = 0
fpsCounterTime = 0

running = false
audio = true

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

  totalTime += elapsedTime if running

  gameTime =
    elapsedGameTime: elapsedTime
    totalGameTime: totalTime

  projectGaia.update gameTime
  projectGaia.draw gameTime

  requestAnimationFrame gameLoop

requestAnimationFrame gameLoop

worlds = document.getElementsByClassName('worlds')[0]
worldButtons = document.getElementsByClassName('world-button')
startButton = document.getElementsByClassName('start-button')[0]
controls = document.getElementsByClassName('controls')[0]
audioButton = document.getElementsByClassName('audio-button')[0]
fullscreenButton = document.getElementsByClassName('fullscreen-button')[0]
body = document.getElementsByTagName('body')[0]

for worldButton in worldButtons
  do (worldButton) =>
    worldButton.onclick = =>
      urlParameters = new URLSearchParams window.location.search
      worldIndex = urlParameters.get('world') or 0

startButton.onclick = =>
  running = true
  projectGaia.start()

  startButton.classList.add 'fade-out'
  startButton.innerText = ''

  worlds.classList.remove 'start'
  controls.classList.remove 'fade-out'

  setTimeout =>
    startButton.remove()
  ,
    1000

audioButton.onclick = =>
  if audio
    projectGaia.mute()
    audioButton.classList.add 'off'

  else
    projectGaia.unmute()
    audioButton.classList.remove 'off'

  audio = not audio

fullscreenButton.onclick = =>
  if document.fullscreenElement || document.webkitFullscreenElement
    document.exitFullscreen?()
    document.webkitExitFullscreen?()

  else
    if body.requestFullscreen
      body.requestFullscreen()

    else if body.webkitRequestFullscreen
      body.webkitRequestFullscreen()

onFullscreenChange = (event) =>
  if document.fullscreenElement || document.webkitFullscreenElement
    worlds.classList.add 'fade-out'

  else
    worlds.classList.remove 'fade-out'

body.addEventListener 'fullscreenchange', onFullscreenChange
body.addEventListener 'webkitfullscreenchange', onFullscreenChange
