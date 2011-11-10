require 'goliath'
require 'goliath/plugins/latency'
require 'json'
require 'pp'

# Broker Class
# rabbitmq proxy for Event Service
class Broker < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Render, 'json'
  use Goliath::Rack::Tracer
  use Goliath::Rack::DefaultMimeType
  use Goliath::Rack::Heartbeat
  use Goliath::Rack::Validation::RequestMethod, %w(GET POST)
  use Goliath::Rack::Validation::RequiredParam, {:key => 'room'}

  # plugin Goliath::Plugin::Latency       # output reactor latency every second


  # on close action
  # TODO must close RoomWorker connection
  def on_close(env)
    # This is just to make sure if the Heartbeat fires we don't try
    # to close a connection.
    return unless env['subscription']

    env.channel.unsubscribe(env['subscription'])
    env.logger.info "Stream connection closed."
  end


  # Process POST request
  # Send message to the RoomBroker
  # Generate a room uuid
  def send_msg_to_room(env)
    pp env.params
    logger.info "Processing request POST"
    room = env.params['room']
    id = env.params['id']
    data = env.params['data']
    payload = "id: #{id}\ndata: #{data}\n"
    broker = RoomBrokerFactory.get(env, room)
    broker.publish(payload)
    [200, {}, 'Ok']
  end


  # Process subscriptions
  # Get the RoomBroker with the RoomBrokerFactory
  # @return [Stream] stream for this room
  def subscribe_to_room(env)
    logger.info "Processing request get"
    room = env.params['room']

    # Init connection
    EM.add_timer(1) do
      init_stream =":" << Array.new(2048, " ").join << "\n"
      env.stream_send(init_stream)
    end

    broker = RoomBrokerFactory.get(env, room)
    broker.consumer_channel.subscribe do |msg|
      msg = msg << "\n"
      logger.info "Sending: #{msg}"
      env.stream_send(msg)
    end

    headers = {
      'Access-Control-Allow-Origin' => '*',
      'Content-Type' => 'text/event-stream',
      'Cache-Control' => 'no-cache',
      'Connection' => 'keep-alive'
    }

    [200, headers , Goliath::Response::STREAMING]
  end

  # Route request
  def response(env)
    logger.info "routing #{env['PATH_INFO']}"
    case env['PATH_INFO']
    when '/subscribe'     then subscribe_to_room(env)
    when '/send'          then send_msg_to_room(env)
    else                  raise Goliath::Validation::NotFoundError
    end
  end
end
