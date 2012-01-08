require 'json'
module Neighborparrot

  # Handle send request
  def prepare_request(env)
    channel = env.params['channel']
    data = env.params['data']
    env.logger.debug "Sent #{data} to channel #{channel}"

    broker = get_channel(env, channel)

    broker.publish pack_message_event(data)
  end

end
