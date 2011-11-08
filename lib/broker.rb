require 'goliath'

# Broker Class
# rabbitmq proxy for Event Service
class Broker < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Render, 'json'
  use Goliath::Rack::Heartbeat
  use Goliath::Rack::Validation::RequestMethod, %w(GET POST)

  # on close action
  # TODO must close RoomWorker connection
  def on_close(env)
    # This is just to make sure if the Heartbeat fires we don't try
    # to close a connection.
    return unless env['subscription']

    env.channel.unsubscribe(env['subscription'])
    env.logger.info "Stream connection closed."
  end


  # Process long time GET request
  # Get the RoomBroker with the RoomBrokerFactory
  # @return [Stream] stream for this room
  def response(env)
    room = env.params['room']
    if room.nil?
      raise Goliath::Validation::BadRequestError.new("Invalid room param.")
    end

    broker = RoomBrokerFactory.get(env, room)
    broker.consumer_channel.subscribe do |msg|
      env.stream_send(msg)
    end
    [200, {}, Goliath::Response::STREAMING]
  end

  # Process POST request
  # Send message to the RoomBroker
  def process_request(env)
    room = env.params['room']
    payload = env.params['payload']

    if room.nil?
      [404, {"Content-Type" => "text/html"}, ["Invalid request"]]
    end
    logger.info "Processing request"
    broker = RoomBrokerFactory.get(env, room)
    broker.publish(payload)
    {response: "ok"}
  end
end
