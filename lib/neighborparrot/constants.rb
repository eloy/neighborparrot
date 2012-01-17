module Neighborparrot
  ROOT_PATH     = File.expand_path(File.dirname(__FILE__) + '/../../')
  SERVER_URL    = "https://neighborparrot.net"
  ASSETS_URL    = "https://neighborparrot.com"
  SERVICES      = %w(ws es) # WebSockets, EventSource
  WS_INDEX      = "#{ROOT_PATH}/templates/web_sockets.html.erb"
  ES_INDEX      = "#{ROOT_PATH}/templates/event_source.html.erb"
end
