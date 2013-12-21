###

  youtubeManager

  2013 (c) Andrey Popp <8mayday@gmail.com>

###

class YoutubeSound

  extractIdRe = /v=([^&]+)/

  constructor: (options) ->
    this.options = options

    this.buffered = undefined
    this.bytesLoaded = undefined
    this.bytesTotal = 1
    this.isBuffering = undefined
    this.connected = undefined
    this.duration = undefined
    this.durationEstimate = undefined
    this.isHTML5 = false
    this.loaded = false
    this.muted = false
    this.paused = false
    this.playState = undefined
    this.position = 0
    this.readyState = 0
    
    this.element = document.createElement 'div'
    this.element.setAttribute 'id', options.id
    this.element.setAttribute 'class', 'ym-container'
    
    document.body.appendChild(this.element)

    # we don't want to change original options
    this._autoPlay = this.options.autoPlay

    this._whileplaying = undefined
    this._whileloading = undefined
    this._previousState = undefined

    videoId = options.youtubeVideoId or extractIdRe.exec(options.url)[1]

    if not videoId?
      throw new Error("cannot extract videoId from URL: #{options.url}")
    
    this.videoId = videoId
    this.player = new YT.Player options.id,
      height: options.height
      width: options.width
      videoId: videoId
      events:
        onReady: => this.onReady()
        onStateChange: => this.onStateChange()
      playerVars:
        controls: '0'
        enablejsapi: '1'
        modestbranding: '1'
        showinfo: '0'
        playerapiid: options.id

  onReady: ->
    this.duration = this.durationEstimate = this.player.getDuration() * 1000
    if this._autoPlay
      this.play()
    this.setVolume this.options.volume if this.options.volume?
    this._startLoadingPoller()

  onStateChange: ->
    state = this.player.getPlayerState()

    if state == -1
      this.duration = this.durationEstimate = this.player.getDuration() * 1000

    if state == YT.PlayerState.PLAYING
      this.duration = this.durationEstimate = this.player.getDuration() * 1000
      this._startPlayingPoller()
      this.paused = false
      if this._previousState == YT.PlayerState.PAUSED
        this.options.onresume.apply(this) if this.options.onresume
      else
        this.options.onplay.apply(this) if this.options.onplay
    else if state == YT.PlayerState.PAUSED
      this._stopPlayingPoller()
      this.paused = true
      this.options.onpause.apply(this) if this.options.onpause
    else if state == YT.PlayerState.ENDED
      this.paused = false
      this._stopPlayingPoller()
      this.options.onfinish.apply(this) if this.options.onfinish

    this._previousState = state

  _startPlayingPoller: ->
    this._whileplaying = setInterval(
      (=> this._updatePosition()),
      this.options.pollingInterval or 500)

  _stopPlayingPoller: ->
    return unless this._whileplaying
    clearInterval(this._whileplaying)
    this._whileplaying = undefined

  _updatePosition: ->
    this.position = this.player.getCurrentTime() * 1000
    this.options.whileplaying.apply(this) if this.options.whileplaying
    
  _startLoadingPoller: ->
    this._whileloading = setInterval(
      (=> this._updateLoading()),
      this.options.pollingInterval or 500)
  
  _stopLoadingPoller: ->
    return unless this._whileloading
    clearInterval(this._whileloading)
    this._whileloading = undefined
  
  _updateLoading: ->
    this.bytesLoaded = this.player.getVideoLoadedFraction()
    if this.bytesLoaded == 1
      this.loaded = true
      this.options.onload.apply(this) if this.options.onload
      this._stopLoadingPoller()
    this.options.whileloading.apply(this) if this.options.whileloading

  destruct: ->
    this.player.destroy()

  load: ->

  clearOnPosition: ->

  onPosition: ->

  mute: ->
    this.muted = true
    this.player.mute()

  pause: ->
    if this.player.pauseVideo?
      this.player.pauseVideo()
    else
      this._autoPlay = false

  play: ->
    if this.player.playVideo?
      this.player.playVideo()
    else
      this._autoPlay = true

  resume: ->
    this.play()

  setPan: ->

  setPosition: (ms) ->
    this.player.seekTo(ms / 1000)

  setVolume: (v) ->
    this.player.setVolume(v)

  stop: ->
    if this.player.stopVideo?
      this.player.seekTo(0)
      this.player.stopVideo()
      this._stopPlayingPoller()
      this._stopLoadingPoller()
      this.position = 0
    else
      this._autoPlay = false

  toggleMute: ->
    if this.player.isMuted()
      this.unmute()
    else
      this.mute()

  togglePause: ->
    if this.player.getPlayerState() == YT.PlayerState.PLAYING
      this.pause()
    else
      this.play()

  unload: ->

  unmute: ->
    this.muted = false
    this.player.unMute()

youtubeManager =

  createSound: (options) ->
    new YoutubeSound(options)

  setup: (options = {}) ->
    oldCallback = window.onYouTubeIframeAPIReady if window.onYouTubeIframeAPIReady?
    window.onYouTubeIframeAPIReady = ->
      options.onready() if options.onready
      oldCallback() if oldCallback
    this._injectScript()

  _injectScript: ->
    tag = document.createElement('script')
    if window.location.host == 'localhost'
      tag.src = "http://www.youtube.com/player_api"
    else
      tag.src = "//www.youtube.com/player_api"
    firstScriptTag = document.getElementsByTagName('script')[0]
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)

define(youtubeManager) if define?.amd?
module.exports = youtubeManager if module?.exports?
