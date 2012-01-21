module Neighborparrot
  # Subscriber connection representation
  module Connection

    # Message counter
    @@next_message_id = 1

    # Create a connection
    # Create a queue for the connection
    # Locate the desired channel and susbcribe thier queue to the channel
    def prepare_connection(env)
      env.trace 'init connection'
      @env = env
      @channel = env.params['channel']
      @env.logger.debug "Connected to channel #{@channel}"
      init_queue
      @queue.push ": " << Array.new(2048, " ").join << "\n\n" # Init stream
      # keep_alive_timer # Not neede??
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

    def send_to_client(msg)
      @env.trace 'sending_chunk'
      # @env.logger.debug "Send message msg to connection X in channel #{@channel}"
      @env.chunked_stream_send msg
    end

    def keep_alive_timer
      @timer = EventMachine::PeriodicTimer.new(Neighborparrot::KEEP_ALIVE_TIMER) do
        @queue.push ':\n\n' # Empty event stream
      end
    end

    # Subscribe to desired channel
    def subscribe
      @env.trace 'subscribing'
      @env.logger.debug "Subscribing the connection to the channel"
      @broker = @application.get_broker(@channel)
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

    # Handle send request
    def prepare_send_request(env)
      env.trace 'prepare send request'
      unless env.params['event_id']
        env.params['event_id'] = generate_message_id
      end
      input_queue.push env.params
      return env.params['event_id']
    end

    # Send the message to the broker for
    # broadcast to other clients
    def send_to_broker(request)
      # env.logger.debug "Sent message to channel #{request[:channel]}"
      env.trace 'sending to broker'
      # Send messages to broker is a slow task
      EM.next_tick do
        message = pack_message_event(request)
        @application.send_message_to_channel request[:channel], message
      end
      env.trace 'sended to broker'
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
      return "id:#{request[:event_id]}\ndata:#{request[:data]}\n\n"
    end

    # All incoming request are pushed to this queue
    # and it send the request to send_to_broker
    private
    @@global_input_queue = nil
  end
end
