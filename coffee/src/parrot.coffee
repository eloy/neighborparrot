# NeighborParrot client
#
class window.Parrot
#  @brokerHost = "https://neighborparrot.net"
  @brokerHost = "http://10.254.0.250:9000"
  @debug = true

  # Parrot constructot
  # @param [String] channel name
  # @param [Function] onmessage: callback called when receive a message
  # @param [Function] onconnect: callback called when connection success
  # @param [Function] onerror: callback called on error
  constructor: (params) ->
    @params = params
    @service = @params['service']
    @channel = @params['channel']
    @log "Creating a parrot with channel: #{@channel}"
    @createIFrame()
    @addMessageListener()

  # Let the window listen messages from the iframe
  addMessageListener: ->
    _this = @
    bounder = (e) -> _this.dispatch.call _this, e
    if window['addEventListener']
      window.addEventListener 'message', bounder
    else
      window.attachEvent 'onmessage', bounder
    # TODO: if Postmessage is not supported??

  # Post message to the iframe window
  post: (data) ->
    msg = JSON.stringify data
    frame = window.document.getElementById('parrot-iframe')
    frame.contentWindow.postMessage msg, Parrot.brokerHost

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
    else if msg.match("^iframeReady:")
      @onIFrameReady()
      @log "IFrame ready"
    else
      @error "ERROR: Invalid message"

  # Create the IFrame for cross domain post message
  createIFrame: ->
    @log "Creating IFrame it not present"
    if $("iframe#parrot-iframe").length == 0
      url_params = "?parent_url=#{@getUrl()}"
      url_params += "&service=#{@service}"
      # Add polyfill if needed
      if @service == 'es'
        url_params += "&use_polyfill=true" unless window['EventSource']
      else
        url_params += "&use_polyfill=true" unless window['WebSocket']
      src = "#{Parrot.brokerHost}/#{url_params}"
      @iframe = $('<iframe>', { id: 'parrot-iframe', src: src})
      @iframe.hide().appendTo('body')
      @log "Created IFrame"

  onIFrameReady: ->
    @post {action: 'connect', params: @params}

  send: (message) ->
    @post {action: 'send', data: message}

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
