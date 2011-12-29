#
# Broker service
$ ->
  @app = window.app ? {}

  parent_url = 'http://superchat.dev:8080/'

  # Post message to the parent window
  post = (data) ->
    $.postMessage(data, parent_url, parent)

  # On connection open send a control event to the parrot
  onEventSourceOpen = (event) ->
    post('connect:')

  # On connection error send a control event to the parrot
  onEventSourceError = (event) ->
    post("error:#{event}")

  # On message post to the parent window
  onEventSourceMessage = (event) ->
    post("data:#{event.data}")

  # make connection and add event listeners
  es = new EventSource('/test');
  es.addEventListener('open', onEventSourceOpen, false);
  es.addEventListener('message', onEventSourceMessage, false);
  es.addEventListener('error', onEventSourceError, false);