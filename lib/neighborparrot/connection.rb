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
      initialize_connection # Defined in each endpoint
      @application.stat_connection_open #
      @channel = env.params['channel']
      @env.logger.debug "Connected to channel #{@channel}"
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
      @env.logger.debug "Subscribing the connection to the channel"
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
    def prepare_send_request(env)
      env.trace 'prepare send request'
      env.logger.debug "Prepare to send messate to channel #{@channel}"
      unless env.params['event_id']
        env.params['event_id'] = generate_message_id
      end
      input_queue.push env.params
      return env.params['event_id']
    end

    # Send the message to the broker for
    # broadcast to other clients
    def send_to_broker(request)
      env.logger.debug "Sent message to broker channel #{request['channel']}"
      env.trace 'sending to broker'
      # Send messages to broker is a slow task
      EM.next_tick do
        message = pack_message_event(request)
        @application.send_message_to_channel request['channel'], message
        env.trace 'sended to broker'
      end
    end

    # Queue for input messages
    # All incoming request are pushed to this queue
    # and it send the request to send_to_broker
    def input_queue
      if @@global_input_queue.nil?
        @@global_input_queue = EM::Queue.new
        processor = proc { |request|
          send_to_broker request
          @@global_input_queue.pop(&processor)
        }
        @@global_input_queue.pop(&processor)
      end
      return @@global_input_queue
    end

    # Generate the message ID to be used as incoming reguest
    def generate_message_id
      @@next_message_id += 1
    end

    # Prepare a message as data message
    def pack_message_event(request)
      return "id:#{request['event_id']}\ndata:#{request['data']}\n\n"
    end

    # All incoming request are pushed to this queue
    # and it send the request to send_to_broker
    private
    @@global_input_queue = nil
  end
end
