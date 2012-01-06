(function() {
  var dummy, serverParam, _ref;

  serverParam = getParam('server');

  serverParam = 'http://127.0.0.1:9000';

  if (serverParam) Parrot.brokerHost = serverParam;

  dummy = function() {};

  this.app = (_ref = window.app) != null ? _ref : {};

  this.app.dummy = dummy;

}).call(this);
