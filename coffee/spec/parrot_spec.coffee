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
    @expectedBufferSize = 8
    that = @
    onmessage = (data) -> that.testBuffer.push data
    iscompleted = -> return that.testBuffer.length == that.expectedBufferSize
    parrot = new Parrot("test-channel", onmessage)

    waitsFor(iscompleted, "test pattern complete", 10000)
    runs ->
      expect(that.testBuffer.length).toEqual(that.expectedBufferSize)
      for i in [1..that.expectedSize]
        expectedSize = i  * 256
        expectedMessage = ''
        for n in [1..expectedSize]
          expectedMessage += '#'
        console.log "test length: #{expectedSize} => #{expectedMessage}"
        expect(that.testBuffer[i]).toEqual(expectedMessage)
      parrot.close()




