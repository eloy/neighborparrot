# Try to get server name param from url and useit if present
serverParam = getParam('server')
serverParam = 'http://127.0.0.1:9000'
Parrot.brokerHost = serverParam if serverParam

dummy = () ->


@app = window.app ? {}
@app.dummy = dummy
