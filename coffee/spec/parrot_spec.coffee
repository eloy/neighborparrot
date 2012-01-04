Parrot.brokerHost = "http://localhost:9000"

describe "Parrot", ->
  it "Should create a iframe on create", ->
    parrot = new Parrot("dummy", app.dummy)
    expect($("iframe#parrot-iframe").length).toEqual(1)
    parrot.close()
    expect($("iframe#parrot-iframe").length).toEqual(0)

  it "Should receive onconnect when connection is open", ->
    @connected = false
    that = @
    onload = (event) -> that.connected = true
    isconnected = -> return that.connected

    parrot = new Parrot("dummy", app.dummy, app.dummy, onload)
    waitsFor(isconnected, "connection open", 10000)
    runs ->
      expect(that.connected).toBeTruthy()
      parrot.close()

  it "Should receive test pattern when connect to test channel", ->
    @testBuffer = []
    that = @
    onmessage = (data) -> that.testBuffer.push data
    iscompleted = -> return that.testBuffer.length == 26
    parrot = new Parrot("test-channel", onmessage)

    waitsFor(iscompleted, "test pattern complete", 10000)
    runs ->
      expect(that.testBuffer.length).toEqual(26)
      parrot.close()




