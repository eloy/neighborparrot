(function() {

  window.Parrot = (function() {

    function Parrot(channel) {
      var that;
      that = this;
      window.setTimeout(that.onconnect, 250);
    }

    Parrot.prototype.onconnect = function() {};

    return Parrot;

  })();

}).call(this);
