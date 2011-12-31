require "rubygems"

# Channel for testing
class TestChannelBroker
    attr_reader :consumer_channel

  # Initialize EM channel for internal distribution
  def initialize()
    @consumer_channel = EM::Channel.new
    start()
  end

  # Unsubscribe when no more users in this channel
  # TODO
  def unsubscribe
    # @channel.unsubscribe()
  end


  # Connect to the given channel
  # and setup connection handler
  def start
    EM.add_periodic_timer(1) {
      data = Time::now
      @consumer_channel.push "Hello!, the time is #{data}"
    }
  end
end
