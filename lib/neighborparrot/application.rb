module Neighborparrot

  # Customer application model
  # Mantain application data, channels and users
  # store persistent data like max connections and in mongodb
  class Application

    attr_reader :api_id, :api_key

    # Global application Hash.
    # Contains all the application instances indexed by api_id
    @@applications = Hash.new

    # Initializer, setup app_info values
    def initialize(env, app_info)
      @env = env
      @app_info = app_info
      @api_id = @app_info[:api_id]
      @api_key = @app_info[:api_key]
      @brokers = {}
    end

    # Return the application with desired api_id
    # Create new record from mongo data if not loaded
    # or nil if api_id do not correspond with any app
    # @param [String] api_id
    # @return [Application] application
    def self.get_application(api_id)
      @@applications[api_id]
    end

    # Create a new application with desired app_info
    def self.generate(env, app_info)
      return false unless app_info
      app = Application.new(env, app_info)
      @@applications[app.api_id] = app
      app
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
      if @env.config['use_rabbit'] == true
        broker = AMQPChannelBroker.new(channel)
        broker.start
      else
        broker = ChannelBroker.new(channel)
      end
      return broker
    end
  end
end
