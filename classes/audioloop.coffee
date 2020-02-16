class ProjectGaia.AudioLoop
  constructor: (@options) ->
    @options.loadingManager.itemStart @options.url

    @options.topVolume ?= 1
    @volume = @options.topVolume
    @targetVolume = @volume

    @audio = new Audio @options.url
    @audio.volume = 0

    @audio.addEventListener 'canplaythrough', (event) =>
      @duration = @audio.duration

      if @options.crossoverDuration
        @nextAudio = new Audio @options.url
        @nextAudio.volume = 0

      else
        @audio.loop = true

      @options.loadingManager.itemEnd @options.url
      
  play: ->
    @audio.play()

  mute: ->
    @targetVolume = 0
    @_startTargetVolumeChange 0.5

  unmute: ->
    @targetVolume = @options.topVolume
    @_startTargetVolumeChange 4.0

  _startTargetVolumeChange: (duration) ->
    @_timeToVolumeChangeEnd = duration
    @_volumeChangeRate = (@targetVolume - @volume) / @_timeToVolumeChangeEnd

  update: (gameTime) ->
    if @_timeToVolumeChangeEnd > 0
      @_timeToVolumeChangeEnd = Math.max 0, @_timeToVolumeChangeEnd - gameTime.elapsedGameTime

      @volume = @targetVolume - @_volumeChangeRate * @_timeToVolumeChangeEnd

    time = @audio.currentTime

    if @options.crossoverDuration
      fadeInVolume = time / @options.crossoverDuration
      fadeOutVolume = (@duration - time) / @options.crossoverDuration
      fadeVolume = THREE.MathUtils.clamp Math.min(fadeInVolume, fadeOutVolume), 0, 1

    else
      fadeVolume = 1

    @audio.volume = fadeVolume * @volume

    if @nextAudio and not @nextAudio.paused
      @nextAudio.volume = (1 - fadeVolume) * @volume

    if @options.crossoverDuration
      # If we've entered the crossover section, start the second audio.
      if @nextAudio.paused and time >= @duration - @options.crossoverDuration
        @nextAudio.currentTime = 0
        @nextAudio.play()

      # If the first audio has reached the end, swap the audios.
      if @audio.ended or time > @duration
        @audio.pause()
        [@audio, @nextAudio] = [@nextAudio, @audio]
