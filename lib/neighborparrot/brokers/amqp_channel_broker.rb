require 'amqp'

module Neighborparrot
  USE_RABBITMQ = true
end

# Channel Broker with AMQP support
# Gets messages from rabbitmq and sends to
# channel members via Event Machine channel
class AMQPChannelBroker
  attr_reader :consumer_channel

  @@_connection = nil
  def self.get_connection(conf)
    unless @@_connection
      @_connection = AMQP.connect(conf)
    end
  end

  # Initialize EM channel for internal distribution
  def initialize(env, room = AMQ::Protocol::EMPTY_STRING)
    @room = room
    @connection = AMQPChannelBroker.get_connection(env.rabbit_conf)
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
    # payload = "#{payload}\n" if !payload.end_with? "\n"
    @provider_queue.publish(payload)
  end

  def start
    @provider_queue = AMQP::Channel.new(@connection, :auto_recovery => true).fanout(@room)
    @channel = AMQP::Channel.new(@connection, :auto_recovery => true)
    @channel.on_error(&method(:handle_channel_exception))
    @queue = @channel.queue("", :auto_delete => true).bind(@room)
    @queue.subscribe(&method(:handle_message))
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
