# NeighborParrot client
class window.Parrot
  @brokerHost = "https://neighborparrot.net"
  @debug = false


  # Parrot constructot
  # @param [String] channel name
  # @param [Function] onmessage: callback called when receive a message
  # @param [Function] onconnect: callback called when connection success
  # @param [Function] onerror: callback called on error
  constructor: (channel, onmessage = null, onerror = null, onconnect = null) ->
    @log "Creating a parrot with channel: #{channel}"
    @channel = channel
    @onmessage = onmessage
    @onconnect = onconnect
    @onerror = onerror
    @createIFrame()
    @addMessageListener()
    @log "Constructor create successful with channel #{channel}"

  addMessageListener: ->
    _this = @
    bounder = (e) -> _this.dispatch.call _this, e
    if window['addEventListener']
      window.addEventListener 'message', bounder
    else
      window.attachEvent 'onmessage', bounder
    # TODO: if not supported??

  # Convenient function for logging
  log: (msg) ->
    console.log msg if @debug
  error: (msg) ->
    console.warn msg if @debug

  # Remove the iframe closing the connection
  close: () ->
    @removeIFrame()
    @log "Parrot closed"

  # Receive the event and call the desired callback
  dispatch: (event) ->
    return if event.origin != Parrot.brokerHost
    msg = event.data
    @log "Dispatching message: @{msg}"
    if msg.match("^data:")
      @onmessage(msg.substring(5))
      @log "Calling onmessage callout"
    else if msg.match("^open:") && @onconnect
      @onconnect()
      @log "Calling onconnect callout"
    else if msg.match("^error:") && @onerror
      @onerror(msg.substring(6))
      @log "Calling onerror callout"
    else
      @error "ERROR: Invalid message"

  # Create the IFrame for cross domain post message
  createIFrame: ->
    @log "Creating IFrame it not present"
    if $("iframe#parrot-iframe").length == 0
      url_params = "?channel=#{@channel}&parent_url=#{@getUrl()}"
      src = "#{Parrot.brokerHost}#{url_params}"
      iframe = $('<iframe>', { id: 'parrot-iframe', src: src})
      iframe.hide().appendTo('body')
      @log "Created IFrame"

  # Return current url for message origin authentication
  getUrl: ->
    protocol = $(location).attr('protocol')
    host = $(location).attr('host')
    url = "#{protocol}//#{host}/"
    @log "The current URL is : #{url}"
    return url

  # Remove the Iframe from the window
  removeIFrame: ->
    $("iframe#parrot-iframe").remove()
