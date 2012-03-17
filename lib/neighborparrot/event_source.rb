class EventSourceEndPoint < Goliath::API
  include Neighborparrot::Connection
  include Neighborparrot::Auth

  # Default headers for Event Source
  # TODO 'Last-Event-Id' => '1'
  HEADERS = { 'Access-Control-Allow-Origin' => '*',
    'Content-Type' => 'text/event-stream',
    'Cache-Control' => 'no-cache',
    'Connection' => 'keep-alive',
    'Transfer-Encoding' => 'chunked',
    'X-STREAM' => 'Neighborparrot',
    'SERVER' => 'Neighborparrot'
  }

  # Actions taken if login failed
  def login_failed
    @env.chunked_stream_send "Login failed"
    @env.chunked_stream_close
  end

  # Prepare a message as data message
  def pack_event_source_message(message)
    id = message.delete(:id)
    return "id:#{message[:id]}\ndata:#{message.to_json}\n\n"
  end

  # Last step in the message live,
  # just send the message to the client stream
  def send_to_client(msg)
    env.trace 'sending_chunk'
    @env.chunked_stream_send pack_event_source_message msg
  end

  def initialize_connection(env)
    env.chunked_stream_send ": " << Array.new(2048, " ").join << "\n\n"
    @keep_alive_timer = EventMachine::PeriodicTimer.new(Neighborparrot::KEEP_ALIVE_TIMER) do
      env.chunked_stream_send ':\n\n' # Empty event stream
    end
  end

  def close_endpoint
    @keep_alive_timer.cancel if @keep_alive_timer
  end

  # Prepare the event source connection
  def response(env)
    @env = env
    env.trace 'open connection'
    validate_connection_params# Ensure required parameters

    authenticated = authenticate
    if authenticated
      EM.next_tick { prepare_connection env }
      chunked_streaming_response(200, HEADERS)
    else
      [401, {}, "Unauthorized"]
    end
  end
end
