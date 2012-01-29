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
    env.chunked_stream_send "Login failed"
    env.chunked_stream_close
  end

  def send_to_client(msg)
    env.trace 'sending_chunk'
    # @env.logger.debug "Send message #{msg} to connection X in channel #{@channel}"
    env.chunked_stream_send msg
  end

  # Prepare the event source connection
  def response(env)
    env.trace 'open connection'
    validate_connection_params # Ensure required parameters

    EM.next_tick do
      auth_request do |app|
       prepare_connection env
      end
    end

    chunked_streaming_response(200, HEADERS)
  end
end
