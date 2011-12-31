# Mantain active channels connections
class ChannelBrokerFactory
  @@channel_brokers = Hash.new
  @@testChannel = nil

  # Return a ChannelBroker for the
  # channel gived or create if not exist
  def self.get(env, channel)
    return self.getTestChannel if channel == "test-channel"

    if @@channel_brokers.has_key? channel
      return @@channel_brokers[channel]
    end

    worker = ChannelBroker.new(env.connection, channel)
    worker.start
    @@channel_brokers[channel] = worker
    return worker
  end

  def self.getTestChannel
    unless @@testChannel
      @@testChannel = TestChannelBroker.new
    end
    @@testChannel
  end
end
