# Mantain active rooms connections
class RoomBrokerFactory
  @@room_brokers = Hash.new

  # Return a RoomBroker for the
  # room gived or create if not exist
  def self.get(env, room)
    if @@room_brokers.has_key? room
      return @@room_brokers[room]
    end

    worker = RoomBroker.new(env.connection, room)
    worker.start
    @@room_brokers[room] = worker
    return worker
  end
end
