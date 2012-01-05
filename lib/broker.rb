# require 'goliath/plugins/latency'

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
# rabbitmq proxy for Event Service
class Broker < Goliath::API
  use Goliath::Rack::Params

  # Don't serve static pages on production
  unless Goliath.prod?
    use Rack::Static, :urls => ["/js", "/tests"], :root => Goliath::Application.app_path("../public")
  end

  # use Goliath::Rack::Tracer
  # use Goliath::Rack::Heartbeat
  # use Goliath::Rack::Validation::RequiredParam, {:key => 'channel'}
  # plugin Goliath::Plugin::Latency       # output reactor latency every second

  # on close action
  # TODO must close ChannelWorker connection
  def on_close(env)
    begin
      if env['SUBSCRIBER']
        env['SUBSCRIBER'][:broker].consumer_channel.unsubscribe(env['SUBSCRIBER'][:sid])
      end
      env.logger.info "Stream connection closed"
    rescue
      env.logger.error $!
    end
  end


  # Process POST request
  # Send message to the ChannelBroker
  # Generate a channel uuid
  def send_msg_to_channel(env)
#    use Goliath::Rack::Validation::RequestMethod, %w(POST)
    channel = env.params['channel']
    data = env.params['data']
    broker = ChannelBrokerFactory.get(env, channel)
    broker.publish(data)
    [200, {}, 'Ok']
  end


  # Process subscriptions
  # Get the ChannelBroker with the ChannelBrokerFactory
  # @return [Stream] stream for this channel
  def subscribe_to_channel(env)
    channel = env.params['channel']
    key = env.params['key']
    env['SUBSCRIBER'] = { :key => key, :channel => channel }

    begin
      # Init connection
      EM.add_timer(1) do
        init_stream =": " << Array.new(2048, " ").join << "\n\n"
        env.stream_send(init_stream)
      end

      broker = ChannelBrokerFactory.get(env, channel)
      sid = broker.consumer_channel.subscribe do |msg|
        env.stream_send "data:#{msg}\n\n"
      end

      env['SUBSCRIBER'][:sid] = sid
      env['SUBSCRIBER'][:broker] = broker

      headers = {
        'Access-Control-Allow-Origin' => '*',
        'Content-Type' => 'text/event-stream',
        'Cache-Control' => 'no-cache',
        'Connection' => 'keep-alive'
      }

      [200, headers , Goliath::Response::STREAMING]

    rescue
      env.logger.error $!
      env.close
    end
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
    logger.info "routing #{env['PATH_INFO']}"
    case env['PATH_INFO']
    when '/' then render_index(env)
    when '/open'     then subscribe_to_channel(env)
    when '/post'     then send_msg_to_channel(env)
    else             raise Goliath::Validation::NotFoundError
    end
  end
end
