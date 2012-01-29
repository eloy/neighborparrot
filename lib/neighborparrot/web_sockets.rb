#require 'goliath/websocket'

class WebSocketEndPoint < Goliath::WebSocket
  include Neighborparrot::Connection
  include Neighborparrot::Auth

  def login_failed
    env.stream_send "Login failed"
    env.stream_close
  end

  def on_open(env)
    env.logger.debug "open WebSocket connection"
    env.trace 'open WebSocket connection'
    validate_connection_params # Ensure required parameters
    EM.next_tick do
      auth_request do |app|
        prepare_connection env
      end
    end
  end

  # WebSockets don't need extra initialization
  def initialize_connection
  end

  def close_endpoint
  end

  def send_to_client(msg)
    @env.trace 'sending_chunk'
    # @env.logger.debug "Send message #{msg} to connection X in channel #{@channel}"
    @env.stream_send msg
  end

  def on_message(env, message)
    env.logger.info("WS MESSAGE: #{message}")
    @application.send_message_to_channel @channel, message
  end

  def on_error(env, error)
    env.logger.error error
  end
end
