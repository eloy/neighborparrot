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
class ConnectionHandler < Goliath::API
  include Neighborparrot

  use Goliath::Rack::Params

  # Don't serve static pages on production
  unless Goliath.prod?
    use Rack::Static, :urls => ["/js", "/tests"], :root => Goliath::Application.app_path("/../../public")
  end

  # Only use the tracer for test purposes
  use Goliath::Rack::Tracer if Goliath.test?


  # use Goliath::Rack::Heartbeat
  # use Goliath::Rack::Validation::RequestMethod, %w(POST)
  # use Goliath::Rack::Validation::RequiredParam, {:key => 'channel'}

  #  plugin Goliath::Plugin::Latency       # output reactor latency every second

  # Init Netighborparrot
  def initialize(opts = {})
    @opts = opts
    prepare_input_queue
  end

  # on close action
  def on_close(env)
    begin
      env['np_connection'].on_close if env['np_connection']
    rescue
      env.logger.error $!
    end
  end

  # Process POST request
  # Send message to the ChannelBroker
  # Generate a channel uuid
  def send(env)
    [200, {}, prepare_send_request(env)]
  end


  def open(env)
    env.trace 'open connection'
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

    template = get_index_template env
    [200, headers, template]
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
