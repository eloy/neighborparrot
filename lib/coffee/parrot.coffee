class window.Parrot

  constructor: ->
    app.parrot = {}
    app.parrot.callbacks = {}

  # Connect with the neighbor broker
  # Accept a array with this options
  # onmessage: callback called when receive a message
  # onconnect: callback called when connection success
  # onerror: callback called on error
  connect: (o)->
    app.parrot.callbacks.onmessage = o.onmessage
    app.parrot.callbacks.onconnect = o.onconnect
    app.parrot.callbacks.onerror = o.onerror

    $.receiveMessage(@dispatch)

  dispatch: (event) ->
    msg = event.data
    if msg.match("^data:")
      app.parrot.callbacks.onmessage(msg.substring(5))

    else if msg.match("^connect:") && app.parrot.callbacks.onconnect
      app.parrot.callbacks.onconnect

    if msg.match("^error:") && app.parrot.callbacks.onerror
      app.parrot.callbacks.onerror(msg.substring(6))



@app = window.app ? {}