
  window.Parrot = (function() {

    Parrot.brokerHost = "http://superchat.dev:9000";

    Parrot.brokerSrc = "" + Parrot.brokerHost + "/index.html";

    function Parrot(channel, onmessage, onerror, onconnect) {
      if (onmessage == null) onmessage = null;
      if (onerror == null) onerror = null;
      if (onconnect == null) onconnect = null;
      this.channel = channel;
      this.onmessage = onmessage;
      this.onconnect = onconnect;
      this.onerror = onerror;
      this.createIFrame();
      $.receiveMessage(this, this.dispatch, Parrot.brokerHost);
    }

    Parrot.prototype.close = function() {
      return this.removeIframe();
    };

    Parrot.prototype.dispatch = function(event) {
      var msg;
      msg = event.data;
      if (msg.match("^data:")) {
        return this.onmessage(msg.substring(5));
      } else if (msg.match("^open:") && this.onconnect) {
        return this.onconnect();
      } else if (msg.match("^error:") && this.onerror) {
        return this.onerror(msg.substring(6));
      }
    };

    Parrot.prototype.createIFrame = function() {
      var src, url_params;
      if ($("iframe#parrot-iframe").length === 0) {
        url_params = "?channel=" + this.channel + "&parent_url=" + (this.getUrl());
        src = "" + Parrot.brokerSrc + url_params;
        this.iframe = $('<iframe>', {
          id: 'parrot-iframe',
          src: src
        });
        return this.iframe.hide().appendTo('body');
      }
    };

    Parrot.prototype.getUrl = function() {
      var host, protocol;
      protocol = $(location).attr('protocol');
      host = $(location).attr('host');
      return "" + protocol + "//" + host + "/";
    };

    Parrot.prototype.removeIFrame = function() {
      return this.iframe.remove();
    };

    return Parrot;

  })();
