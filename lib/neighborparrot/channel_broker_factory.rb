# Mantain active channels connections
module Neighborparrot

  @@channel_brokers = Hash.new

  # Return a ChannelBroker for the
  # channel gived or create if not exist
  def get_channel(env, channel)
    return TestChannelBroker.new() if channel == "test-channel"

    if @@channel_brokers.has_key? channel
      return @@channel_brokers[channel]
    end

    if USE_RABBITMQ
      broker = AMQPChannelBroker.new(env, channel)
      broker.start
    else
      broker = ChannelBroker.new(env, channel)
    end
    @@channel_brokers[channel] = broker

    return broker
  end
end
