require "rubygems"
require "amqp"

# Gets messages from rabbitmq and sends to
# channel members via Event Machine channel
class ChannelBroker
  attr_reader :consumer_channel

  # Initialize EM channel for internal distribution
  def initialize(connection, channel = AMQ::Protocol::EMPTY_STRING)
    @channel = channel
    @connection = connection
    @consumer_channel = EM::Channel.new
  end

  # Unsubscribe when no more users in this channel
  # TODO
  def unsubscribe
    # @channel.unsubscribe()
  end

  # Send payload to rabbitmq queue
  # @param [String] payload to send
  def publish(payload)
    # payload must end with \n
    payload = "#{payload}\n" if !payload.end_with? "\n"
    @provider_queue.publish(payload)
  end

  # Connect to the given channel
  # and setup connection handler
  def start
    @provider_queue = AMQP::Channel.new(@connection).fanout(@channel)
    @channel = AMQP::Channel.new(@connection)
    @channel.on_error(&method(:handle_channel_exception))
    @queue = @channel.queue(@channel, :auto_delete => true).bind(@provider_queue)
    @queue.subscribe(&method(:handle_message))
    @consumer_channel.push "Welcome".to_json
  end

  # Reply rabbitmq paylod to channel members
  def handle_message(metadata, payload)
    @consumer_channel.push payload
  end

  # Manage channel exceptions
  # TODO
  def handle_channel_exception(channel, channel_close)
    puts "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"
  end
end
