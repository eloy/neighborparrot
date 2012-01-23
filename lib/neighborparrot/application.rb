module Neighborparrot

  # Customer application model
  # Mantain application data, channels and users
  # store persistent data like max connections and in mongodb
  class Application

    attr_accessor :api_id

    # Global application Hash.
    # Contains all the application instances indexed by api_id
    @@applications = Hash.new

    # Initializer, setup app_info values
    def initialize(api_id)
      @api_id = api_id
      @brokers = {}
    end

    # Return the application with desired api_id
    # Create new record from mongo data if not loaded
    # or nil if api_id do not correspond with any app
    # @param [String] api_id
    # @return [Application] application
    def self.get_application(api_id)
      app = @@applications[api_id]
      return app unless app.nil?
      @@applications[api_id] = Application.new(api_id)
    end

    # Get or create a channel
    def get_broker(channel)
      broker = @brokers[channel]
      return broker unless broker.nil?
      @brokers[channel] = create_broker(channel)
      @brokers[channel]
    end

    # Send desired message to channel
    def send_message_to_channel(channel, message)
      broker = @brokers[channel]
      return if broker.nil?
      broker.publish message
    end

    # Return a ChannelBroker
    def create_broker(channel)
      # return TestChannelBroker.new() if channel == "test-channel"
      if false
        broker = AMQPChannelBroker.new(channel)
        broker.start
      else
        broker = ChannelBroker.new(channel)
      end
      return broker
    end
  end
end
