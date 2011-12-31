# Broker service
class window.Broker
  # Broker constructor
  # Get channel and parent url from the parameters
  constructor: ->
    @channel = @getParam('channel')
    @parent_url = @getParam('parent_url')

  # Extract parameters from the url. Trigger error if not found
  # @param [String] name of the parameter
  # @return [String] value for the parameter if present
  getParam: (name) ->
    results = new RegExp('[\\?&]' + name + '=([^&#]*)').exec(window.location.href)
    if results && results.length > 0
      return results[1]
    @onEventSourceError({data: "Unset parameter #{name}"})


  # Post message to the parent window
  post: (data) ->
    $.postMessage(data, @parent_url, parent)

  # On connection open send a control event to the parrot
  onEventSourceOpen: (event) ->
    app.broker.post('open:')

  # On connection error send a control event to the parrot
  onEventSourceError:  (event) ->
    app.broker.post("error:#{event.data}")

  # On message post to the parent window
  onEventSourceMessage: (event) ->
    app.broker.post("data:#{event.data}")

  # open connection and add event listeners
  # Called from index.html in the broker server
  open: ->
    es = new EventSource("/open?channel=#{@channel}");
    es.addEventListener('open', @onEventSourceOpen, false);
    es.addEventListener('message', @onEventSourceMessage, false);
    es.addEventListener('error', @onEventSourceError, false);

@app = window.app ? {}
