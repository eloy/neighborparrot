require 'json'
module Neighborparrot

  # Handle send request
  def prepare_send_request(env)
    env.trace 'prepare send request'
    unless env.params['event_id']
      env.params['event_id'] = generate_message_id
    end
    @@input_queue.push env.params
    return env.params['event_id']
  end

  def send_to_broker(request)
    # env.logger.debug "Sent message to channel #{request[:channel]}"
    env.trace 'looking channel'
    broker = @@channel_brokers[request[:channel]]
    env.trace 'sending to broker'
    return if broker.nil?
    # Send messages to broker is a slow task
    EM.next_tick { broker.publish pack_message_event(request) }
    env.trace 'sended to broker'
  end

  private
  def prepare_input_queue
    @@input_queue = EM::Queue.new
    processor = proc { |request|
      send_to_broker request
      @@input_queue.pop(&processor)
    }
    @@input_queue.pop(&processor)
  end
end
