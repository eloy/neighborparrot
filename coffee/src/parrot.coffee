# NeighborParrot client
#
class window.Parrot
#  @brokerHost = "https://neighborparrot.net"
  @brokerHost = "http://10.254.0.250:9000"
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

  addMessageListener: ->
    _this = @
    bounder = (e) -> _this.dispatch.call _this, e
    if window['addEventListener']
      window.addEventListener 'message', bounder
    else
      window.attachEvent 'onmessage', bounder
    # TODO: if Postmessage is not supported??

  # Convenient function for logging
  log: (msg) ->
    console.log msg if @debug
  error: (msg) ->
    console.warn msg if @debug

  # Remove the iframe closing the connection
  close: () ->
    @removeIFrame()
    @log "Parrot closed"

  parseMessage: (msg) ->
    { data: msg.substring(5) }

  # Receive the event and call the desired callback
  dispatch: (event) ->
    return if event.origin != Parrot.brokerHost
    msg = event.data
    @log "Dispatching message: @{msg}"
    if msg.match("^data:")
      @onmessage @parseMessage msg
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
      url_params += "&use_polyfill=true" unless window['EventSource'] # Add polyfill if needed
      src = "#{Parrot.brokerHost}/#{url_params}"
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
