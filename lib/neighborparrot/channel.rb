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

    # Return current subscription for desired user
    # @param [Integer] user_id
    # @return [Array] array of subscriptions
    def subscriptions_for(user_id)
      subs = []
      @subscriptors.each do |key, s|
        subs.push key if s[:user_id] == user_id
      end
      return subs
    end

    # Return unique subscriptos
    # Each user can connect from many sources
    # each with their own subscription_id
    # @return [Array] with presence hash for unique user
    def unique_subscriptors
      h = { }
      @subscriptors.each_value do |s|
        h[s[:user_id]] = s
      end
      h.values
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
