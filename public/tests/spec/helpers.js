(function() {
  var dummy, serverParam, _ref;

  serverParam = getParam('server');

  if (serverParam) Parrot.brokerHost = serverParam;

  dummy = function() {};

  this.app = (_ref = window.app) != null ? _ref : {};

  this.app.dummy = dummy;

}).call(this);
