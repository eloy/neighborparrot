
  $(function() {
    var es, onEventSourceError, onEventSourceMessage, onEventSourceOpen, parent_url, post, _ref;
    this.app = (_ref = window.app) != null ? _ref : {};
    parent_url = 'http://superchat.dev:8080/';
    post = function(data) {
      return $.postMessage(data, parent_url, parent);
    };
    onEventSourceOpen = function(event) {
      return post('connect:');
    };
    onEventSourceError = function(event) {
      return post("error:" + event);
    };
    onEventSourceMessage = function(event) {
      return post("data:" + event.data);
    };
    es = new EventSource('/test');
    es.addEventListener('open', onEventSourceOpen, false);
    es.addEventListener('message', onEventSourceMessage, false);
    return es.addEventListener('error', onEventSourceError, false);
  });
