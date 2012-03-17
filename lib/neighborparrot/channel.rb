module Neighborparrot

  class Channel
    include Neighborparrot::Stats
    include Neighborparrot::Logger

    attr_reader :name, :subscriptors

    def initialize(name, app_info)
      @name = name
      @app_info = app_info
      @subscriptors = Hash.new
      create_broker
    end

    # Subscribe to desired channel and perform the block
    # with msg arg, and add the connection to the channel
    # if presence enabled
    # @return [int] subscription_id for later disconnect
    def subscribe(endpoint, block)
      subscription_id = @broker.consumer_channel.subscribe do |msg|
        block.call msg
      end

      @subscriptors[subscription_id] = endpoint.presence
      return subscription_id
    end

    # Unsubscribe from desired channed and remove the user
    # from the connections hash
    def unsubscribe(subscription_id)
      @broker.consumer_channel.unsubscribe(subscription_id)
      @subscriptors.delete subscription_id
    end

    # Send the given message to all connections subscribed
    def publish(message)
      @broker.publish message
    end

    # Return the listeners in this channel
    def listeners_count
      @subscriptors.size()
    end

    # Return a ChannelBroker
    def create_broker
      if false # AMQP is very experimental
        key = "#{@app_info['api_id']}-#{@name}"
        @broker = AMQPChannelBroker.new(key)
        @broker.start
      else
        @broker = ChannelBroker.new(@name)
      end
    end
  end
end
