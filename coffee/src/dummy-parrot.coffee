# Parrot used in test enviroments
class window.Parrot
  constructor: (channel) ->
    that = @
    window.setTimeout(that.onconnect,250)

  onconnect: ->
