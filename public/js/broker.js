(function() {
  var _ref;

  window['getParam'] = function(name) {
    var results;
    results = new RegExp('[\\?&]' + name + '=([^&#]*)').exec(window.location.href);
    if (results && results.length > 0) return results[1];
  };

  window.Broker = (function() {

    function Broker() {
      this.channel = window.getParam('channel');
      this.parent_url = window.getParam('parent_url');
    }

    Broker.prototype.post = function(data) {
      return $.postMessage(data, this.parent_url, parent);
    };

    Broker.prototype.onEventSourceOpen = function(event) {
      return app.broker.post('open:');
    };

    Broker.prototype.onEventSourceError = function(event) {
      return app.broker.post("error:" + event.data);
    };

    Broker.prototype.onEventSourceMessage = function(event) {
      return app.broker.post("data:" + event.data);
    };

    Broker.prototype.open = function() {
      var es;
      es = new EventSource("/open?channel=" + this.channel);
      es.addEventListener('open', this.onEventSourceOpen, false);
      es.addEventListener('message', this.onEventSourceMessage, false);
      return es.addEventListener('error', this.onEventSourceError, false);
    };

    return Broker;

  })();

  this.app = (_ref = window.app) != null ? _ref : {};

}).call(this);
