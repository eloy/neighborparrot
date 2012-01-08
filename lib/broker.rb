require 'goliath/plugins/latency'
module Rack
   class Static
     def can_serve(path)
       return false if path == "/"
       return true if path.index('/js') == 0
       return true if path.index('/tests') == 0
     end
   end
 end


# Broker Class
class Broker < Goliath::API
  use Goliath::Rack::Params

  # Don't serve static pages on production
  unless Goliath.prod?
    use Rack::Static, :urls => ["/js", "/tests"], :root => Goliath::Application.app_path("../public")
  end

  # use Goliath::Rack::Tracer
  # use Goliath::Rack::Heartbeat
  # use Goliath::Rack::Validation::RequestMethod, %w(POST)
  # use Goliath::Rack::Validation::RequiredParam, {:key => 'channel'}

  #  plugin Goliath::Plugin::Latency       # output reactor latency every second

  # on close action
  def on_close(env)
    begin
      env['np_connection'].on_close if env['np_connection']
    rescue
      env.logger.error $!
    end
  end

  @next_message_id = 1
  # Process POST request
  # Send message to the ChannelBroker
  # Generate a channel uuid
  def send(env)
    EM.next_tick do
      env['np_connection'] = Neighborparrot::SendRequest.new(env)
    end
    [200, {}, 'Ok']
  end


  def open(env)
    EM.next_tick do
      env['np_connection'] = Neighborparrot::Connection.new(env)
    end
    chunked_streaming_response(200, Neighborparrot::EventSourceHeaders)
  end

  def render_index(env)
    headers = {
      'Access-Control-Allow-Origin' => '*',
      'Content-Type' => 'text/html',
      'Cache-Control' => 'no-cache',
    }
    [200, headers, INDEX_TEMPLATE]
  end

  # Route request
  def response(env)
    case env['PATH_INFO']
    when '/' then render_index(env)
    when '/open'     then open(env)
    when '/send'     then send(env)
    else             raise Goliath::Validation::NotFoundError
    end
  end
end
