# NeighborParrot client
class window.Parrot
  @brokerHost = "http://superchat.dev:9000"
  @brokerSrc = "#{@brokerHost}/index.html"

  # Parrot constructot
  # @param [String] channel name
  # @param [Function] onmessage: callback called when receive a message
  # @param [Function] onconnect: callback called when connection success
  # @param [Function] onerror: callback called on error
  constructor: (channel, onmessage = null, onerror = null, onconnect = null) ->
    @channel = channel
    @onmessage = onmessage
    @onconnect = onconnect
    @onerror = onerror
    @createIFrame()
    $.receiveMessage @, @dispatch, Parrot.brokerHost

  # Remove the iframe closing the connection
  close: () ->
    @removeIframe()

  # Receive the event and call the desired callback
  dispatch: (event) ->
    msg = event.data
    if msg.match("^data:")
      @onmessage(msg.substring(5))
    else if msg.match("^open:") && @onconnect
      @onconnect()
    else if msg.match("^error:") && @onerror
      @onerror(msg.substring(6))

  # Create the IFrame for cross domain post message
  createIFrame: ->
    if $("iframe#parrot-iframe").length == 0
      url_params = "?channel=#{@channel}&parent_url=#{@getUrl()}"
      src = "#{Parrot.brokerSrc}#{url_params}"
      @iframe = $('<iframe>', { id: 'parrot-iframe', src: src})
      @iframe.hide().appendTo('body')

  # Return current url for message origin authentication
  getUrl: ->
    protocol = $(location).attr('protocol')
    host = $(location).attr('host')
    return "#{protocol}//#{host}/" # Must end with /

  # Remove the Iframe from the window
  removeIFrame: ->
    @iframe.remove()
