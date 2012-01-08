require 'json'
module Neighborparrot

  class SendRequest
    @@next_message_id = 1

    def initialize(env)
      @env = env
      @channel = @env.params['channel']
      prepare_request
    end

    def prepare_request
      data = @env.params['data']
      @env.logger.debug "Sent #{data} to channel #{@channel}"
      broker = ChannelBrokerFactory.get(@env, @channel)
      broker.publish format_event(data)
      @@next_message_id += 1
    end

    # Prepare a message as data message
    def format_event(data)
      return "id:#{@@next_message_id}\ndata:#{data}\n\n"
    end

    def close
    end
  end
end
