(function() {

  window.Parrot = (function() {

    Parrot.brokerHost = "http://10.254.0.250:9000";

    Parrot.WEBSOCKET_SERVER = "ws://10.254.0.250:9000";

    Parrot.debug = true;

    function Parrot(params) {
      this.params = params;
      this.service = this.params['service'];
      this.channel = this.params['channel'];
      this.log("Creating a parrot with channel: " + this.channel);
      if (this.service === 'es') {
        this.createIFrame();
        this.addMessageListener();
      } else {
        if (window['WebSocke']) {
          this.openWebSocket();
        } else {
          this.loadPolyfillsAndOpen(this.params);
        }
      }
    }

    Parrot.prototype.close = function() {
      if (this.service === 'es') {
        return this.closeEventSource();
      } else {
        return this.closeWebSocket();
      }
    };

    Parrot.prototype.log = function(msg) {
      if (this.debug) return console.log(msg);
    };

    Parrot.prototype.error = function(msg) {
      if (this.debug) return console.warn(msg);
    };

    Parrot.prototype.dispatch = function(event) {
      var msg;
      if (event.origin !== Parrot.brokerHost) return;
      msg = event.data;
      this.log("Dispatching message: @{msg}");
      if (msg.match("^data:")) {
        this.onmessage(this.parseMessage(msg));
        return this.log("Calling onmessage callout");
      } else if (msg.match("^open:") && this.onopen) {
        this.onopen();
        return this.log("Calling onopen callout");
      } else if (msg.match("^error:") && this.onerror) {
        this.onerror(msg.substring(6));
        return this.log("Calling onerror callout");
      } else if (msg.match("^iframeReady:")) {
        this.onIFrameReady();
        return this.log("IFrame ready");
      } else {
        return this.error("ERROR: Invalid message");
      }
    };

    Parrot.prototype.addMessageListener = function() {
      var bounder, _this;
      _this = this;
      bounder = function(e) {
        return _this.dispatch.call(_this, e);
      };
      if (window['addEventListener']) {
        return window.addEventListener('message', bounder);
      } else {
        return window.attachEvent('onmessage', bounder);
      }
    };

    Parrot.prototype.parseMessage = function(msg) {
      return {
        data: msg.substring(5)
      };
    };

    Parrot.prototype.closeEventSource = function() {
      this.removeIFrame();
      return this.log("Parrot closed");
    };

    Parrot.prototype.createIFrame = function() {
      var src, url_params;
      this.log("Creating IFrame it not present");
      if ($("iframe#parrot-iframe").length === 0) {
        url_params = "?parent_url=" + (this.getUrl());
        url_params += "&service=" + this.service;
        if (!window['EventSource']) url_params += "&use_polyfill=true";
        src = "" + Parrot.brokerHost + "/" + url_params;
        this.iframe = $('<iframe>', {
          id: 'parrot-iframe',
          src: src
        });
        this.iframe.hide().appendTo('body');
        return this.log("Created IFrame");
      }
    };

    Parrot.prototype.onIFrameReady = function() {
      return this.post({
        action: 'connect',
        params: this.params
      });
    };

    Parrot.prototype.getUrl = function() {
      var host, protocol, url;
      protocol = $(location).attr('protocol');
      host = $(location).attr('host');
      url = "" + protocol + "//" + host + "/";
      this.log("The current URL is : " + url);
      return url;
    };

    Parrot.prototype.removeIFrame = function() {
      return $("iframe#parrot-iframe").remove();
    };

    Parrot.prototype.post = function(data) {
      var frame, msg;
      msg = JSON.stringify(data);
      frame = window.document.getElementById('parrot-iframe');
      return frame.contentWindow.postMessage(msg, Parrot.brokerHost);
    };

    Parrot.prototype.openWebSocket = function() {
      var url, _this;
      _this = this;
      url = "" + Parrot.WEBSOCKET_SERVER + "/" + (this.toQuery('ws', this.params));
      this.ws = new window.WebSocket(url);
      this.ws.addEventListener('open', function(e) {
        return _this.onopen.call(_this, e);
      }, false);
      this.ws.addEventListener('message', function(e) {
        return _this.onmessage.call(_this, e);
      }, false);
      return this.ws.addEventListener('error', function(e) {
        return _this.onerror.call(_this, e);
      }, false);
    };

    Parrot.prototype.send = function(msg) {
      if (this.ws) return this.ws.send(msg);
    };

    Parrot.prototype.closeWebSocket = function() {
      if (this.ws) return this.ws.close;
    };

    Parrot.prototype.toQuery = function(path, params) {
      var key, query, value;
      query = "" + path + "?";
      for (key in params) {
        value = params[key];
        query += "&" + key + "=" + value;
      }
      return query;
    };

    Parrot.prototype.loadPolyfillsAndOpen = function(params) {
      var counter, head, loader, _this;
      this.params = params;
      head = document.getElementById('head');
      this.loadPolyfills();
      _this = this;
      counter = 0;
      loader = function() {
        if (window['WebSocket'] || counter > 10) {
          return _this.openWebSocket();
        } else {
          counter += 1;
          return setTimeout(loader, 100);
        }
      };
      return setTimeout(loader, 100);
    };

    Parrot.prototype.loadPolyfills = function() {
      var head, js, polyfills, src, _i, _len, _results;
      window.WEB_SOCKET_SWF_LOCATION = "http://10.254.0.250:9000/pf/WebSocketMain.swf";
      window.WEB_SOCKET_SUPPRESS_CROSS_DOMAIN_SWF_ERROR = true;
      polyfills = ['swfobject.js', 'web_socket.js'];
      head = document.getElementById('head');
      _results = [];
      for (_i = 0, _len = polyfills.length; _i < _len; _i++) {
        src = polyfills[_i];
        js = document.createElement('script');
        js.type = "text/javascript";
        js.src = "http://10.254.0.250:9000/pf/" + src;
        _results.push(head.appendChild(js));
      }
      return _results;
    };

    return Parrot;

  })();

}).call(this);
