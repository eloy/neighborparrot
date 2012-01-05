# Mantain active channels connections
class ChannelBrokerFactory
  @@channel_brokers = Hash.new

  # Return a ChannelBroker for the
  # channel gived or create if not exist
  def self.get(env, channel)
    return TestChannelBroker.new() if channel == "test-channel"

    if @@channel_brokers.has_key? channel
      return @@channel_brokers[channel]
    end

    # For RabbitMQ brokers
    broker = AMQPChannelBroker.new(env, channel)
    broker.start

    #broker = ChannelBroker.new(env, channel)
    #@@channel_brokers[channel] = broker

    return broker
  end
end
