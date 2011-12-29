(function() {
  var _ref;

  window.Parrot = (function() {

    function Parrot() {
      app.parrot = {};
      app.parrot.callbacks = {};
    }

    Parrot.prototype.connect = function(o) {
      app.parrot.callbacks.onmessage = o.onmessage;
      app.parrot.callbacks.onconnect = o.onconnect;
      app.parrot.callbacks.onerror = o.onerror;
      return $.receiveMessage(this.dispatch);
    };

    Parrot.prototype.dispatch = function(event) {
      var msg;
      msg = event.data;
      if (msg.match("^data:")) {
        app.parrot.callbacks.onmessage(msg.substring(5));
      } else if (msg.match("^connect:") && app.parrot.callbacks.onconnect) {
        app.parrot.callbacks.onconnect;
      }
      if (msg.match("^error:") && app.parrot.callbacks.onerror) {
        return app.parrot.callbacks.onerror(msg.substring(6));
      }
    };

    return Parrot;

  })();

  this.app = (_ref = window.app) != null ? _ref : {};

}).call(this);
