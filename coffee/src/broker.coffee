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
  constructor: ->
    @channel = window.getParam('channel')
    @parent_url = window.getParam('parent_url')
    @addMessageListener()
    @post("iframeReady:")

 # Let the window listen messages from the iframe
  addMessageListener: ->
    _this = @
    bounder = (e) -> _this.dispatch.call _this, e
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
  onEventSourceOpen: (event) ->
    @post('open:')

  # On connection error send a control event to the parrot
  onEventSourceError:  (event) ->
    @post("error:#{event.data}")

  # On message post to the parent window
  onEventSourceMessage: (event) ->
    @post("data:#{event.data}")

  # open connection and add event listeners
  # Called from index.html in the broker server
  open: (params)->
    _this = @
    es = new EventSource(@toQuery('/open', params))
    es.addEventListener('open', (e) ->
      _this.onEventSourceOpen.call _this, e
    , false)
    es.addEventListener('message', (e) ->
      _this.onEventSourceMessage.call _this, e
    , false)
    es.addEventListener('error', (e) ->
      _this.onEventSourceError.call _this, e
    , false)

  # Dispatch messages from the main window
  dispatch: (event) ->
    if event.data.action == 'connect'
      @open event.data.params

  toQuery: (path, params) ->
    console.log params
    query = "#{path}?"
    for key,value of params
      query += "&#{key}=#{value}"
    query

@app = window.app ? {}
