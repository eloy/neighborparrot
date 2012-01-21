# Gets messages from rabbitmq and sends to
# channel members via Event Machine channel
class ChannelBroker
  attr_reader :consumer_channel

  # Initialize EM channel for internal distribution
  def initialize(channel)
    @consumer_channel = EM::Channel.new
  end

  # Broadcast data to customers
  def publish(data)
    @consumer_channel.push data
  end
end
