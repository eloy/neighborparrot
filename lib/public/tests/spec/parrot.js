
  describe("Parrot", function() {
    return it("Should create a iframe on connect and removeit on disconnect", function() {
      var parrot;
      parrot = new Parrot();
      parrot.open({
        onmessage: app.dummy
      });
      expect($("iframe#parrot-iframe").length).toEqual(1);
      parrot.close();
      return expect($("iframe#parrot-iframe").length).toEqual(0);
    });
  });
