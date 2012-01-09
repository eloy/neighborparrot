module Neighborparrot

  # Subscriber connection representation
  class Connection
    include Neighborparrot

    # Create a connection
    # Create a queue for the connection
    # Locate the desired channel and susbcribe thier queue to the channel
    def initialize(env)
      env.trace 'init connection'
      @env = env
      @channel = env.params['channel']
      @env.logger.debug "Connected to channel #{@channel}"
      init_queue
      @queue.push ": " << Array.new(2048, " ").join << "\n\n" # Init stream
#      keep_alive_timer
      subscribe
    end

    def init_queue
      @queue = EM::Queue.new
      processor = proc { |msg|
        send_to_client msg
        @queue.pop(&processor)
      }
      @queue.pop(&processor)
    end

    def send_to_client(msg)
      @env.trace 'sending_chunk'
      # @env.logger.debug "Send message msg to connection X in channel #{@channel}"
      @env.chunked_stream_send msg
    end

    def keep_alive_timer
      @timer = EventMachine::PeriodicTimer.new(KEEP_ALIVE_TIMER) do
        @queue.push ':\n\n' # Empty event stream
      end
    end

    def subscribe
      @env.trace 'subscribing'
      @env.logger.debug "Subscribing the connection to the channel"
      @broker = get_channel(@env, @channel)
      @subscription_id = @broker.consumer_channel.subscribe do |msg|
        @queue.push msg
      end
    end

    def close_stream
      @env.chunked_stream_close
    end

    def on_close
      @env.logger.debug "unsubscribe custome from channel #{@channel}"
      @broker.consumer_channel.unsubscribe(@subscription_id)
    end
  end
end
