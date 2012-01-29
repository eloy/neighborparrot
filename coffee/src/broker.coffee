# Extract parameters from the url.
# @param [String] name of the parameter
# @return [String] value for the parameter if present
window['getParam'] = (name) ->
  results = new RegExp('[\\?&]' + name + '=([^&#]*)').exec(window.location.href)
  if results && results.length > 0
    return results[1]


# Broker service
class window.Broker
  # Broker constructor
  # Get channel and parent url from the parameters
  constructor: (service, server=nil) ->
    @service = service
    @server = server
    @channel = window.getParam('channel')
    @parent_url = window.getParam('parent_url')
    @addMessageListener(@service)
    @post("iframeReady:")

 # Let the window listen messages from the iframe
  addMessageListener: (service) ->
    _this = @
    if service == 'es'
      bounder = (e) -> _this.dispatchEventSource.call _this, e
    else
      bounder = (e) -> _this.dispatchWebSocket.call _this, e

    if window['addEventListener']
      window.addEventListener 'message', bounder
    else
      window.attachEvent 'onmessage', bounder
    # TODO: if Postmessage is not supported??

  # Post message to the parent window
  post: (data) ->
    target_url = @parent_url.replace( /([^:]+:\/\/[^\/]+).*/, '$1' )
    parent.postMessage data, target_url

  # On connection open send a control event to the parrot
  on_open: (event) ->
    @post('open:')

  # On connection error send a control event to the parrot
  on_error:  (event) ->
    @post("error:#{event.data}")

  # On message post to the parent window
  on_message: (event) ->
    @post("data:#{event.data}")

  # open connection and add event listeners
  # Called from index.html in the broker server
  openEventSource: (params)->
    _this = @
    es = new EventSource(@toQuery('/open', params))
    es.addEventListener('open', (e) ->
      _this.on_open.call _this, e
    , false)
    es.addEventListener('message', (e) ->
      _this.on_message.call _this, e
    , false)
    es.addEventListener('error', (e) ->
      _this.on_error.call _this, e
    , false)

  # open connection and add event listeners
  # Called from index.html in the broker server
  openWebSocket: (params)->
    _this = @
    url = "#{@server}/#{@toQuery('ws', params)}"
    es = new WebSocket(url)
    es.addEventListener('open', (e) ->
      _this.on_open.call _this, e
    , false)
    es.addEventListener('message', (e) ->
      _this.on_message.call _this, e
    , false)
    es.addEventListener('error', (e) ->
      _this.on_error.call _this, e
    , false)

  # Dispatch messages from the main window
  dispatchEventSource: (event) ->
    if event.data.action == 'connect'
      @openEventSource event.data.params

 # Dispatch messages from the main window
  dispatchWebSocket: (event) ->
    if event.data.action == 'connect'
      @openWebSocket event.data.params


  toQuery: (path, params) ->
    console.log params
    query = "#{path}?"
    for key,value of params
      query += "&#{key}=#{value}"
    query

@app = window.app ? {}
