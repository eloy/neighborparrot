
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
      that = this;
      onmessage = function(data) {
        return that.testBuffer.push(data);
      };
      iscompleted = function() {
        return that.testBuffer.length === 26;
      };
      parrot = new Parrot("test-channel", onmessage);
      waitsFor(iscompleted, "test pattern complete", 10000);
      return runs(function() {
        expect(that.testBuffer.length).toEqual(26);
        return parrot.close();
      });
    });
  });
