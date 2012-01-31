module Neighborparrot
  class Channel
    include Neighborparrot::Stats
    attr_reader :name

    def initialize(name, app_info)
      @name = name
      @app_info = app_info
      @connections = Hash.new
      create_broker
    end

    # Subscribe to desired channel and perform the block
    # with msg arg
    # @return [int] subscription_id for later disconnect
    def subscribe(endpoint, block)
      subscription_id = @broker.consumer_channel.subscribe do |msg|
        block.call msg
      end
      conn = {
        :presence_data => endpoint.presence_data
      }
      @connections[subscription_id] = conn
      return subscription_id
    end

    def unsubscribe(subscription_id)
      @broker.consumer_channel.unsubscribe(subscription_id)
      @connections.delete subscription_id
    end

    # Send the given message to all connections subscribed
    def publish(message)
      @broker.publish message
    end

    def listeners_count
      @connections.size()
    end
    # Return a ChannelBroker
    def create_broker
      if false
        key = "#{@app_info['api_id']}-#{@name}"
        @broker = AMQPChannelBroker.new(key)
        @broker.start
      else
        @broker = ChannelBroker.new(@name)
      end
    end
  end
end
