# Channel for testing
# Reproduce a test pattern
class TestChannelBroker
  include Neighborparrot

    attr_reader :consumer_channel

  # Initialize EM channel for internal distribution
  def initialize()
    @consumer_channel = EM::Channel.new
    start()
  end

  # Connect to the given channel
  # and setup connection handler
  def start
    EM::Iterator.new(1..8).each do |n,iter|
      size = n * 256
      message =  Array.new(size, "#").join
      @consumer_channel.push pack_message_event message
      iter.next
    end
  end
end
