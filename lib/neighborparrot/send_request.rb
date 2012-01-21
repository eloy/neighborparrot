class SendRequestEndPoint < Goliath::API
  include Neighborparrot::Connection
  include Neighborparrot::Auth


  # on close action
  def on_close(env)

  end

  # Prepare the event source connection
  def response(env)
    env.trace 'open send connection'
    validate_send_params env.params # Ensure required parameters

    EM.next_tick do
      auth_send_request do |app|
        prepare_send_request env
      end
    end

    chunked_streaming_response(200, HEADERS)
  end
end

