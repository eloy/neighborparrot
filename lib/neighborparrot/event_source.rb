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
    'X-Stream' => 'Neighborparrot',
    'Server' => 'Neighborparrot'
  }


  # on close action
  def on_close(env)
    begin
      env['np_connection'].on_close if env['np_connection']
    rescue
      env.logger.error $!
    end
  end

  # Prepare the event source connection
  def response(env)
    env.trace 'open connection'
    validate_connection_params env.params # Ensure required parameters

    EM.next_tick do
      auth_connection_request do |app_info|
        env.logger.info  "Ok #{app_info}"
      end
    end

    chunked_streaming_response(200, HEADERS)
  end
end
