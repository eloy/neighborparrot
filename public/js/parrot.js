(function() {

  window.Parrot = (function() {

    Parrot.brokerHost = "http://127.0.0.1:9000";

    Parrot.debug = true;

    function Parrot(params) {
      this.params = params;
      this.channel = this.params['channel'];
      this.log("Creating a parrot with channel: " + this.channel);
      this.createIFrame(this.params['service']);
      this.addMessageListener();
    }

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

    Parrot.prototype.post = function(data) {
      var frame;
      frame = window.document.getElementById('parrot-iframe');
      return frame.contentWindow.postMessage(data, Parrot.brokerHost);
    };

    Parrot.prototype.log = function(msg) {
      if (this.debug) return console.log(msg);
    };

    Parrot.prototype.error = function(msg) {
      if (this.debug) return console.warn(msg);
    };

    Parrot.prototype.close = function() {
      this.removeIFrame();
      return this.log("Parrot closed");
    };

    Parrot.prototype.parseMessage = function(msg) {
      return {
        data: msg.substring(5)
      };
    };

    Parrot.prototype.dispatch = function(event) {
      var msg;
      if (event.origin !== Parrot.brokerHost) return;
      msg = event.data;
      this.log("Dispatching message: @{msg}");
      if (msg.match("^data:")) {
        this.onmessage(this.parseMessage(msg));
        return this.log("Calling onmessage callout");
      } else if (msg.match("^open:") && this.onconnect) {
        this.onconnect();
        return this.log("Calling onconnect callout");
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

    Parrot.prototype.createIFrame = function(service) {
      var src, url_params;
      this.log("Creating IFrame it not present");
      if ($("iframe#parrot-iframe").length === 0) {
        url_params = "?parent_url=" + (this.getUrl());
        url_params += "&service=" + service;
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
      console.log("IFrame preparado");
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

    return Parrot;

  })();

}).call(this);
