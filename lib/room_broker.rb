require "rubygems"
require "amqp"


class RoomBroker
  attr_reader :consumer_channel

  def initialize(connection, queue_name = AMQ::Protocol::EMPTY_STRING)
    @consumer_channel = EM::Channel.new
    @queue_name = queue_name
    @connection = connection
  end

  def unsubscribe
    # @channel.unsubscribe()
  end

  def publish(payload)
    @provider_channel.publish(payload)
  end

  def start
    @provider_channel = AMQP::Channel.new(@connection).fanout(@queue_name)
    @channel = AMQP::Channel.new(@connection)
    @channel.on_error(&method(:handle_channel_exception))
    @queue = @channel.queue(@queue_name, :auto_delete => true).bind(@provider_channel)
    @queue.subscribe(&method(:handle_message))
  end

  def handle_message(metadata, payload)
    @consumer_channel.push payload
  end


  def handle_channel_exception(channel, channel_close)
    puts "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"
  end
end
