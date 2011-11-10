require "rubygems"
require "amqp"

# Gets messages from rabbitmq and sends to
# room members via Event Machine channel
class RoomBroker
  attr_reader :consumer_channel

  # Initialize EM channel for internal distribution
  def initialize(connection, room = AMQ::Protocol::EMPTY_STRING)
    @room = room
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

  # Connect to the given room
  # and setup connection handler
  def start
    @provider_queue = AMQP::Channel.new(@connection).fanout(@room)
    @channel = AMQP::Channel.new(@connection)
    @channel.on_error(&method(:handle_channel_exception))
    @queue = @channel.queue(@room, :auto_delete => true).bind(@provider_queue)
    @queue.subscribe(&method(:handle_message))
    @consumer_channel.push "Welcome".to_json
  end

  # Reply rabbitmq paylod to room members
  def handle_message(metadata, payload)
    @consumer_channel.push payload
  end

  # Manage channel exceptions
  # TODO
  def handle_channel_exception(channel, channel_close)
    puts "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"
  end
end
