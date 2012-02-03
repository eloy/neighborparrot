(function() {
  var _ref;

  window['getParam'] = function(name) {
    var results;
    results = new RegExp('[\\?&]' + name + '=([^&#]*)').exec(window.location.href);
    if (results && results.length > 0) return results[1];
  };

  window.Broker = (function() {

    function Broker(service, server) {
      if (server == null) server = nil;
      this.service = service;
      this.server = server;
      this.channel = window.getParam('channel');
      this.parent_url = window.getParam('parent_url');
      this.addMessageListener(this.service);
      this.post("iframeReady:");
    }

    Broker.prototype.addMessageListener = function(service) {
      var bounder, _this;
      _this = this;
      if (service === 'es') {
        bounder = function(e) {
          return _this.dispatchEventSource.call(_this, e);
        };
      } else {
        bounder = function(e) {
          return _this.dispatchWebSocket.call(_this, e);
        };
      }
      if (window['addEventListener']) {
        return window.addEventListener('message', bounder);
      } else {
        return window.attachEvent('onmessage', bounder);
      }
    };

    Broker.prototype.post = function(data) {
      var target_url;
      target_url = this.parent_url.replace(/([^:]+:\/\/[^\/]+).*/, '$1');
      return parent.postMessage(data, target_url);
    };

    Broker.prototype.on_open = function(event) {
      return this.post('open:');
    };

    Broker.prototype.on_error = function(event) {
      return this.post("error:" + event.data);
    };

    Broker.prototype.on_message = function(event) {
      return this.post("data:" + event.data);
    };

    Broker.prototype.openEventSource = function(params) {
      var es, _this;
      _this = this;
      es = new EventSource(this.toQuery('/open', params));
      es.addEventListener('open', function(e) {
        return _this.on_open.call(_this, e);
      }, false);
      es.addEventListener('message', function(e) {
        return _this.on_message.call(_this, e);
      }, false);
      return es.addEventListener('error', function(e) {
        return _this.on_error.call(_this, e);
      }, false);
    };

    Broker.prototype.dispatchEventSource = function(event) {
      var msg;
      msg = JSON.parse(event.data);
      if (msg.action === 'connect') {
        return this.openEventSource(msg.params);
      } else {
        return console.log("Desconocido: " + event.data.action);
      }
    };

    Broker.prototype.toQuery = function(path, params) {
      var key, query, value;
      query = "" + path + "?";
      for (key in params) {
        value = params[key];
        query += "&" + key + "=" + value;
      }
      return query;
    };

    return Broker;

  })();

  this.app = (_ref = window.app) != null ? _ref : {};

}).call(this);
