module Neighborparrot
  HOSTNAME       = `hostname`.strip
  ROOT_PATH         = File.expand_path(File.dirname(__FILE__) + '/../../')
  KEEP_ALIVE_TIMER  = 10 # How send keep alive pings in event source
  PUSH_STATS_FREC   = 30 # How ofter stats are pushed to server

  def self.test?
    Neighborparrot.env == :test
  end

  def self.prod?
    Neighborparrot.env == :production
  end

  def self.devel?
    Neighborparrot.env == :development
  end

  def self.env
    Goliath.env rescue ENV['RACK_ENV'] || :development
  end

  if Neighborparrot::prod?
    SERVER_URL        = "https://neighborparrot.net"
    WS_SERVER_URL     = "wss://neighborparrot.net"
    ASSETS_URL        = "https://neighborparrot.com"
  else
    SERVER_URL        = "http://127.0.0.1:9000"
    WS_SERVER_URL     = "ws://10.254.0.250:9000"
    ASSETS_URL        = ""
  end
  SERVICES          = %w(ws es) # WebSockets, EventSource
  WS_INDEX          = "#{ROOT_PATH}/templates/web_sockets.html.erb"
  ES_INDEX          = "#{ROOT_PATH}/templates/event_source.html.erb"
end
