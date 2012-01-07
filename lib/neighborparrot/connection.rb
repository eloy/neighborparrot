module Neighborparrot

  EventSourceHeaders = {
    'Access-Control-Allow-Origin' => '*',
    'Content-Type' => 'text/event-stream',
    'Cache-Control' => 'no-cache',
    'Connection' => 'keep-alive'
  }

  # Subscriber connection representation
  class Connection

    # Create a connection
    # Create a queue for the connection
    # Locate the desired channel and susbcribe thier queue to the channel
    def initialize(env)
      @env = env
      @channel = env.params['channel']
      # @env.logger.debug "Connected to channel #{@channel}"
      init_queue
      init_stream
      subscribe
    end

    def init_queue
      @queue = EM::Queue.new
      processor = proc { |msg|
        # @env.logger.debug "Send message to customer X in channel #{@channel}"
        @env.stream_send msg
        @queue.pop(&processor)
      }
      @queue.pop(&processor)
    end

    # Initialize the stream
    def init_stream
      @queue.push ": " << Array.new(2048, " ").join << "\n\n"
    end

    # Prepare a message as data message
    def data_msg(msg)
      "data:#{msg}\n\n"
    end

    def subscribe
      @broker = ChannelBrokerFactory.get(@env, @channel)
      @subscription_id = @broker.consumer_channel.subscribe do |msg|
        @queue.push data_msg(msg)
      end
    end

    def close
      # @env.logger.debug "unsubscribe custome from channel #{@channel}"
      @broker.consumer_channel.unsubscribe(@subscription_id)
    end
  end
end
