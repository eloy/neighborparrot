require "rubygems"

# Channel for testing
# Reproduce a test pattern
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
    EM.add_timer(1) do
      pattern = %w(Alpha Bravo Charlie Delta Echo Foxtrot Golf Hotel India Juliet Kilo Lima Mike November Oscar Papa Quebec Romeo Sierra Tango Uniform Victor Whiskey Xray Yankee Zulu)
      pattern.each do |w|
        @consumer_channel.push w
      end

    end
  end
end
