module Neighborparrot

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

  ROOT_PATH         = File.expand_path(File.dirname(__FILE__) + '/../../')
  if Neighborparrot::prod?
    SERVER_URL        = "https://neighborparrot.net"
    ASSETS_URL        = "https://neighborparrot.com"
  else
    SERVER_URL        = ""
    ASSETS_URL        = ""
  end
  SERVICES          = %w(ws es) # WebSockets, EventSource
  WS_INDEX          = "#{ROOT_PATH}/templates/web_sockets.html.erb"
  ES_INDEX          = "#{ROOT_PATH}/templates/event_source.html.erb"
  KEEP_ALIVE_TIMER  = 10



end
