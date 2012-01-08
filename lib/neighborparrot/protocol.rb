# Protocol related strings and helpers
module Neighborparrot

  @@next_message_id = 1

  # Generate the message ID to be used as incoming reguest
  def generate_message_id
    @@next_message_id += 1
  end

  # Prepare a message as data message
  def pack_message_event(data)
    id = generate_message_id
    return "id:#{id}\ndata:#{data}\n\n"
  end

  # Connection params
  #-------------------------------------

  # Seconds betwen keep alive pings
  KEEP_ALIVE_TIMER = 25

  # Reply headers
  #-------------------------------------

  EventSourceHeaders = {
    'Access-Control-Allow-Origin' => '*',
    'Content-Type' => 'text/event-stream',
    'Cache-Control' => 'no-cache',
    'Connection' => 'keep-alive',
    'Transfer-Encoding' => 'chunked',
    'X-Stream' => 'Neighborparrot',
    'Server' => 'Neighborparrot',
    'Last-Event-Id' => '1' # TODO
  }

end
