# Try to get server name param from url and useit if present
serverParam = getParam('server')
unless serverParam
  if window.location.host.match('localhost') ||  window.location.host.match('127.0.0.1')
    serverParam = location.origin

Parrot.brokerHost = serverParam if serverParam

dummy = () ->


@app = window.app ? {}
@app.dummy = dummy
