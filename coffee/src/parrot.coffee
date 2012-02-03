# NeighborParrot Event Source client
#
class window.Parrot
  @brokerHost = "https://neighborparrot.net"
  @WEBSOCKET_SERVER = "wss://neighborparrot.net"
  @ASSETS_SERVER = "https://neighborparrot.com"
  @debug = false

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
    if @service == 'es'
      @createIFrame()
      @addMessageListener()
    else
      if window['WebSocket']
        @openWebSocket()
      else
        @loadPolyfillsAndOpen(@params)

  close: ->
    if @service == 'es'
      @closeEventSource()
    else
      @closeWebSocket()

  # Convenient function for logging
  log: (msg) ->
    console.log msg if @debug
  error: (msg) ->
    console.warn msg if @debug

  #===============================================
  # Event Source
  #===============================================

  # Receive the event and call the desired callback
  dispatch: (event) ->
    return if event.origin != Parrot.brokerHost
    msg = event.data
    @log "Dispatching message: @{msg}"
    if msg.match("^data:")
      @onmessage @parseMessage msg
      @log "Calling onmessage callout"
    else if msg.match("^open:") && @onopen
      @onopen()
      @log "Calling onopen callout"
    else if msg.match("^error:") && @onerror
      @onerror(msg.substring(6))
      @log "Calling onerror callout"
    else if msg.match("^iframeReady:")
      @onIFrameReady()
      @log "IFrame ready"
    else
      @error "ERROR: Invalid message"

  # Let the window listen messages from the iframe
  addMessageListener: ->
    _this = @
    bounder = (e) -> _this.dispatch.call _this, e
    if window['addEventListener']
      window.addEventListener 'message', bounder
    else
      window.attachEvent 'onmessage', bounder
    # TODO: if Postmessage is not supported??

  # TODO : remove this!
  parseMessage: (msg) ->
    { data: msg.substring(5) }


  # EventSource IFrame stuff
  #-------------------------

  # Remove the iframe closing the connection
  closeEventSource: () ->
    @removeIFrame()
    @log "Parrot closed"

  # Create the IFrame for cross domain post message
  createIFrame: ->
    @log "Creating IFrame it not present"
    if $("iframe#parrot-iframe").length == 0
      url_params = "?parent_url=#{@getUrl()}"
      url_params += "&service=#{@service}"
      # Add polyfill if needed
      url_params += "&use_polyfill=true" unless window['EventSource']
      src = "#{Parrot.brokerHost}/#{url_params}"
      @iframe = $('<iframe>', { id: 'parrot-iframe', src: src})
      @iframe.hide().appendTo('body')
      @log "Created IFrame"

  onIFrameReady: ->
    @post {action: 'connect', params: @params}

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

  # Post message to the iframe window
  post: (data) ->
    msg = JSON.stringify data
    frame = window.document.getElementById('parrot-iframe')
    frame.contentWindow.postMessage msg, Parrot.brokerHost

  #===============================================
  # WebSocket
  #===============================================

  # open connection and add event listeners
  # Called from index.html in the broker server
  openWebSocket: ->
    _this = @
    url = "#{Parrot.WEBSOCKET_SERVER}/#{@toQuery('ws', @params)}"
    @ws = new window.WebSocket(url)
    @ws.addEventListener('open', (e) ->
      _this.onopen.call _this, e
    , false)
    @ws.addEventListener('message', (e) ->
      _this.onmessage.call _this, e
    , false)
    @ws.addEventListener('error', (e) ->
      _this.onerror.call _this, e
    , false)

  # Send a message to the parrot with WebSocket
  send: (msg) ->
    @ws.send msg if @ws

  # Close the websocket connection
  closeWebSocket: ->
    @ws.close if @ws

  # join replacement
  toQuery: (path, params) ->
    query = "#{path}?"
    for key,value of params
      query += "&#{key}=#{value}"
    query

  loadPolyfillsAndOpen: (@params) ->
    head = document.getElementById('head');
    @loadPolyfills()
    _this = @
    counter = 0
    loader = ->
      if window['WebSocket'] || counter > 10
        _this.openWebSocket()
      else
        counter += 1
        setTimeout(loader, 100)
    setTimeout(loader, 100)

  loadPolyfills: ->
    window.WEB_SOCKET_SWF_LOCATION = "#{@ASSETS_SERVER}/pf/WebSocketMain.swf"
    window.WEB_SOCKET_SUPPRESS_CROSS_DOMAIN_SWF_ERROR = true
    polyfills = ['swfobject.js', 'web_socket.js']
    head = document.getElementById('head');
    for src in polyfills
      js = document.createElement('script')
      js.type = "text/javascript"
      js.src = "#{@ASSETS_SERVER}/pf/#{src}"
      head.appendChild(js)
