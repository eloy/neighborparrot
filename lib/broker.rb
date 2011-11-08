require 'goliath'
require 'goliath/plugins/latency'
require 'json'

# Broker Class
# rabbitmq proxy for Event Service
class Broker < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Render, 'json'
  use Goliath::Rack::Tracer
  use Goliath::Rack::DefaultMimeType
  use Goliath::Rack::Heartbeat
  use Goliath::Rack::Validation::RequestMethod, %w(GET POST)
#  use Goliath::Rack::Validation::RequiredParam, {:key => 'room'}

  plugin Goliath::Plugin::Latency       # output reactor latency every second


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
  def process_post(env)
    room = env.params['room']
    payload = env.params['payload']
    logger.info "Processing request"
    broker = RoomBrokerFactory.get(env, room)
    broker.publish(payload)
    [200, {}, 'Ok']
  end


   # Process long time GET request
  # Get the RoomBroker with the RoomBrokerFactory
  # @return [Stream] stream for this room
  def process_get(env)
    room = env.params['room']
    broker = RoomBrokerFactory.get(env, room)
    broker.consumer_channel.subscribe do |msg|
      env.stream_send(msg)
    end
    [200, {}, Goliath::Response::STREAMING]
  end

  # Route request
  def response(env)
    if env[Goliath::Request::REQUEST_METHOD] == 'POST'
      process_post(env)
    else
      process_get(env)
    end
  end
end
