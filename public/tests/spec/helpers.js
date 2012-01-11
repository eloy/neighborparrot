(function() {
  var dummy, serverParam, _ref;

  serverParam = getParam('server');

  if (!serverParam) {
    if (window.location.host.match('localhost') || window.location.host.match('127.0.0.1')) {
      serverParam = location.origin;
    }
  }

  if (serverParam) Parrot.brokerHost = serverParam;

  dummy = function() {};

  this.app = (_ref = window.app) != null ? _ref : {};

  this.app.dummy = dummy;

}).call(this);
