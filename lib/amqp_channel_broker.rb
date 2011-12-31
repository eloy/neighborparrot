# Channel Broker with AMQP support
require "rubygems"
require "amqp"

# Gets messages from rabbitmq and sends to
# channel members via Event Machine channel
class AMQPChannelBroker
  attr_reader :consumer_channel

  # Initialize EM channel for internal distribution
  def initialize(env, channel = AMQ::Protocol::EMPTY_STRING)
    @channel = channel
    @connection = env.connection
    @logger = env.logger
    @consumer_channel = EM::Channel.new
  end

  # Unsubscribe when no more users in this channel
  # TODO
  def unsubscribe
    # @channel.unsubscribe()
  end

  # Send payload to rabbitmq queue
  # @param [String] payload to send
  def publish(data)
    @logger.info "Sending data: #{data}"
    @provider_queue.publish(data)
  end

  # Connect to the given channel
  # and setup connection handler
  def start
    @provider_queue = AMQP::Channel.new(@connection).fanout(@channel)
    @ampq_channel = AMQP::Channel.new(@connection)
    @ampq_channel.on_error(&method(:handle_channel_exception))
    @queue = @ampq_channel.queue(@channel, :auto_delete => true).bind(@provider_queue)
    @queue.subscribe(&method(:handle_message))
    @consumer_channel.push "Welcome"
  end

  # Reply rabbitmq paylod to channel members
  def handle_message(metadata, data)
    @logger.info "Received #{data}"
    @consumer_channel.push data
  end

  # Manage channel exceptions
  # TODO
  def handle_channel_exception(ampq_channel, channel_close)
    puts "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"
  end
end
