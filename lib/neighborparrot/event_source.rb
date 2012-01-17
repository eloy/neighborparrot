class EventSourceEndPoint < Goliath::API
  include Neighborparrot::Connection

  # on close action
  def on_close(env)
    begin
      env['np_connection'].on_close if env['np_connection']
    rescue
      env.logger.error $!
    end
  end

  def response(env)
    env.trace 'open connection'
    EM.next_tick do
      env['np_connection'] = Neighborparrot::Connection.new(env)
    end
    chunked_streaming_response(200, Neighborparrot::EventSourceHeaders)
  end


end
