# Try to get server name param from url and useit if present
serverParam = getParam('server')
Parrot.brokerHost = serverParam if serverParam

dummy = () ->


@app = window.app ? {}
@app.dummy = dummy
