module Neighborparrot

  # Customer application model
  # Mantain application data, channels and users
  # store persistent data like max connections and in mongodb
  class Application
    include Neighborparrot::Stats

    attr_accessor :api_id

    # Global application Hash.
    # Contains all the application instances indexed by api_id
    @@applications = Hash.new

    # Initializer, setup app_info values
    def initialize(api_id)
      @api_id = api_id
      @channels = {}
      initialize_stats
    end

    # Subscribe to desired channel and perform the block
    # with msg arg
    # @return [int] subscription_id for later disconnect
    def subscribe(endpoint, &block)
      channel = get_channel(endpoint.channel)
      channel.subscribe(endpoint, block)
    end

    def unsubscribe(channel_name, subscription_id)
      channel = @channels[channel_name]
      channel.unsubscribe(subscription_id) if channel
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
    def get_channel(name)
      channel = @channels[name]
      return channel unless channel.nil?
      channel = Neighborparrot::Channel.new(name, @app_info)
      @channels[name] = channel
      channel
    end

    # Send desired message to channel
    def send_message_to_channel(channel_name, message)
      channel = @channels[channel_name]
      return if channel.nil?
      channel.publish message
    end
  end
end
