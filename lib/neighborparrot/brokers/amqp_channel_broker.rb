require 'amqp'

# Channel Broker with AMQP support
# Gets messages from rabbitmq and sends to
# channel members via Event Machine channel
class AMQPChannelBroker
  # Consume channel is the channel used to send
  # the messages back to the connections
  attr_reader :consumer_channel

  @@_connection = nil
  def self.get_connection(conf)
    unless @@_connection
      @_connection = AMQP.connect(conf)
    end
  end

  # Initialize EM channel for internal distribution
  def initialize(room = AMQ::Protocol::EMPTY_STRING)
    @room = room
    @connection = AMQPChannelBroker.get_connection(env.rabbit_conf)
    @consumer_channel = EM::Channel.new
  end

  # Send payload to rabbitmq queue
  # TODO: Send messages to local users via consumer_channel
  # @param [String] payload to send
  def publish(payload)
    @provider_queue.publish(payload)
  end

  # Start a rabbit mq subscription
  def start
    @provider_queue = AMQP::Channel.new(@connection, :auto_recovery => true).fanout(@room)
    @channel = AMQP::Channel.new(@connection, :auto_recovery => true)
    @channel.on_error(&method(:handle_channel_exception))
    @queue = @channel.queue("", :auto_delete => true).bind(@room)
    @queue.subscribe(&method(:handle_message))
  end

  # Reply rabbitmq paylod to room members
  # TODO Local messages should be published via
  # current consumer_channel, btw should ignore local messages here
  def handle_message(metadata, payload)
    @consumer_channel.push payload
  end

  # Manage channel exceptions
  # TODO
  def handle_channel_exception(channel, channel_close)
    env.logger.info "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"
  end
end
