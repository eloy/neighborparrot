
  describe("Parrot", function() {
    it("Should create a iframe on create", function() {
      var parrot;
      parrot = new Parrot("dummy", app.dummy);
      expect($("iframe#parrot-iframe").length).toEqual(1);
      parrot.close();
      return expect($("iframe#parrot-iframe").length).toEqual(0);
    });
    it("Should receive onconnect when connection is open", function() {
      var isconnected, onload, parrot, that;
      this.connected = false;
      that = this;
      onload = function(event) {
        return that.connected = true;
      };
      isconnected = function() {
        return that.connected;
      };
      parrot = new Parrot("dummy", app.dummy, app.dummy, onload);
      waitsFor(isconnected, "connection open", 10000);
      return runs(function() {
        expect(that.connected).toBeTruthy();
        return parrot.close();
      });
    });
    return it("Should receive test pattern when connect to test channel", function() {
      var iscompleted, onmessage, parrot, that;
      this.testBuffer = [];
      this.expectedBufferSize = 8;
      that = this;
      onmessage = function(e) {
        return that.testBuffer.push(e.data);
      };
      iscompleted = function() {
        return that.testBuffer.length === that.expectedBufferSize;
      };
      parrot = new Parrot("test-channel", onmessage);
      waitsFor(iscompleted, "test pattern complete", 10000);
      return runs(function() {
        var expectedMessage, expectedSize, i, n, _ref;
        expect(that.testBuffer.length).toEqual(that.expectedBufferSize);
        for (i = 1, _ref = that.expectedSize; 1 <= _ref ? i <= _ref : i >= _ref; 1 <= _ref ? i++ : i--) {
          expectedSize = i * 256;
          expectedMessage = '';
          for (n = 1; 1 <= expectedSize ? n <= expectedSize : n >= expectedSize; 1 <= expectedSize ? n++ : n--) {
            expectedMessage += '#';
          }
          console.log("test length: " + expectedSize + " => " + expectedMessage);
          expect(that.testBuffer[i]).toEqual(expectedMessage);
        }
        return parrot.close();
      });
    });
  });
