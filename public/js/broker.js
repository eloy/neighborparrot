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
      var target_url;
      target_url = this.parent_url.replace(/([^:]+:\/\/[^\/]+).*/, '$1');
      return parent.postMessage(data, target_url);
    };

    Broker.prototype.onEventSourceOpen = function(event) {
      return this.post('open:');
    };

    Broker.prototype.onEventSourceError = function(event) {
      return this.post("error:" + event.data);
    };

    Broker.prototype.onEventSourceMessage = function(event) {
      return this.post("data:" + event.data);
    };

    Broker.prototype.open = function() {
      var es, _this;
      _this = this;
      es = new EventSource("/open?channel=" + this.channel);
      es.addEventListener('open', function(e) {
        return _this.onEventSourceOpen.call(_this, e);
      }, false);
      es.addEventListener('message', function(e) {
        return _this.onEventSourceMessage.call(_this, e);
      }, false);
      return es.addEventListener('error', function(e) {
        return _this.onEventSourceError.call(_this, e);
      }, false);
    };

    return Broker;

  })();

  this.app = (_ref = window.app) != null ? _ref : {};

}).call(this);
