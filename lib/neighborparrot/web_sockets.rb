#require 'goliath/websocket'

class WebSocketEndPoint < Goliath::WebSocket
  include Neighborparrot::Connection
  include Neighborparrot::Auth

  def on_open(env)
    validate_connection_params env.params
#    env.logger.info("WS OPEN")
#    env['subscription'] = env.channel.subscribe { |m| env.stream_send(m) }
  end

  def on_message(env, msg)
    env.logger.info("WS MESSAGE: #{msg}")
    env.channel << msg
  end

  def on_close(env)
    env.logger.info("WS CLOSED")
    env.channel.unsubscribe(env['subscription'])
  end

  def on_error(env, error)
    env.logger.error error
  end
end
