CUSTOMERS = 4
MIN_CHANNELS = 4
MAX_CHANNELS = 16
MIN_USERS = 5
MAX_USERS = 15

MIN_DELAY = 1
MAX_DELAY = 10


def generate_world(length)
  world = []
  r = Random.new
  for i in 0..CUSTOMERS
    customer =  { :api_id => "API_ID-#{i}", :api_key => "API_KEY-#{i}", :channels => [] }
    channels = r.rand(MIN_CHANNELS..MAX_CHANNELS)
    for c in 0..channels
      users = r.rand(MIN_USERS..MAX_USERS)
      delay = r.rand(MIN_DELAY..MAX_DELAY)
      count = length / MAX_DELAY
      channel = { :id => "#{customer[:api_id]}-#{c}", :users => users, :delay => delay, :count => count }
      customer[:channels].push channel
    end
    world.push customer
  end
  return world
end
