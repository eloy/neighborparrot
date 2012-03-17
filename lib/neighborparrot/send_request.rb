class SendRequestEndPoint < Goliath::API
  include Neighborparrot::Connection
  include Neighborparrot::Auth

  # Default headers
  HEADERS = { 'Access-Control-Allow-Origin' => '*',
    'Content-Type' => 'text/event-stream',
    'Cache-Control' => 'no-cache',
    'Connection' => 'keep-alive',
    'Transfer-Encoding' => 'chunked',
    'X-STREAM' => 'Neighborparrot',
    'SERVER' => 'Neighborparrot'
  }

  # on close action
  def on_close(env)

  end

  # Prepare the event source connection
  def response(env)
    env.trace 'open send connection'
    env.logger.debug "Begin send request"
    validate_send_params  # Ensure required parameters
    if authenticate
      [200, {}, prepare_send_request]
    else
      [401, {}, "Unauthorized"]
    end
  end
end

