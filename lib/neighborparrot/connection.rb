module Neighborparrot
  # Subscriber connection representation
  module Connection
    attr_reader :channel, :application

    # Message counter
    @@next_message_id = 1

    # Create a connection
    # Create a queue for the connection
    # Stat the connection for statistics
    def prepare_connection(env)
      env.trace 'init connection'
      @env = env
      init_queue
      initialize_connection env # Defined in each endpoint
      @application.stat_connection_open
      @channel = env.params['channel']
      logger.debug "Connected to channel #{@channel}"
      subscribe
    end

    # Prepare output queue
    # Messages to this user are pushed to this
    # queue and it send the messages to
    # send_to_client
    def init_queue
      @queue = EM::Queue.new
      processor = proc { |msg|
        send_to_client msg
        @queue.pop(&processor)
      }
      @queue.pop(&processor)
    end

    # Subscribe to desired channel
    def subscribe
      @env.trace 'subscribing'
      @subscription_id = @application.subscribe(self) do |msg|
        @queue.push msg
      end
    end

    # Called when close connection
    # Unsubscribe from current channel and call close_endpoint for
    # service depenent actions
    def on_close(env)
      env.logger.debug "unsubscribe customer from channel #{@channel}"
      if @application
        @application.stat_connection_close
        @application.unsubscribe(@channel, @subscription_id)
      end
      close_endpoint
    end

    # Handle send request
    def prepare_send_request(data=nil)
      data = data || @data
      # @application.stat_connection_open
      event_id = generate_message_id
      message = { :id => event_id, :data => data, :channel => @channel }
      send_to_broker message
      return event_id
    end

    # Send the message to the broker for
    # broadcast to other clients
    def send_to_broker(message)
      env.trace 'sending to broker'
      logger.debug "Sending message to channel #{@channel}"
      EM.next_tick do
        @application.send_message_to_channel @channel, message
        env.trace 'sended to broker'
      end
    end

    # Generate the message ID to be used as incoming reguest
    def generate_message_id
      @@next_message_id += 1
    end
  end
end
