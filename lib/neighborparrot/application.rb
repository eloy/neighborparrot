require 'pp'
module Neighborparrot

  # Customer application model
  # Mantain application data, channels and users
  # store persistent data like max connections and in mongodb
  class Application
    include Neighborparrot::Stats
    include Neighborparrot::Logger

    attr_accessor :api_id, :app_info

    # Global application Hash.
    # Contains all the application instances indexed by api_id
    @@applications = Hash.new

    # Initializer, setup app_info values
    def initialize(api_id)
      @api_id = api_id
      @app_info = nil
      @channels = {}
      initialize_stats
      logger.debug "Created application"
    end

    # Remove application
    # stop timers, flush stats and remove from current_applications
    def destroy
      stop_stats
      @@applications.delete @api_id
    end

    # Subscribe to desired channel and perform the block
    # with msg arg
    # @return [int] subscription_id for later disconnect
    def subscribe(endpoint, &block)
      channel = get_channel(endpoint.channel)
      channel.subscribe(endpoint, block)
    end

    # Unsubscribe connection from channel
    # Remove channel if no more users connected
    # Remove application if no more apps
    def unsubscribe(channel_name, subscription_id)
      channel = @channels[channel_name]
      if channel
        channel.unsubscribe(subscription_id)
        # EM.next_tick { cleanup_after_unsubscribe channel }
        cleanup_after_unsubscribe channel
      else
        logger.debug "Trying to unsubscribe for an inexistant channel #{channel_name}"
      end
    end

    # Validations after unsubcribe
    # Check if is last suscriptor and remove channel
    # and application if needed
    def cleanup_after_unsubscribe(channel)
      return if channel.listeners_count > 0
      logger.debug "destroying channel #{channel.name}"
      @channels.delete channel.name
      stat_channel_destroyed channel.name
      destroy if @channels.size == 0
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
      # If not exists, create it
      logger.debug "Created channel #{name}"
      stat_channel_created name # Stats and log
      @channels[name] = Neighborparrot::Channel.new(name, @app_info)
    end

    # Send desired message to channel
    def send_message_to_channel(channel_name, message)
      logger.debug "Sending in application to channel #{channel_name}"
      channel = @channels[channel_name]
      if channel.nil?
        logger.debug "Trying to send a message to a void channel #{channel_name} en #{self}"
        return
      end
      channel.publish message
      stat_message_sended channel_name
      # TODO: Message received should count messages received in other parrot servers
      # Should be moved to channel
      stat_message_received channel_name, channel.listeners_count
      logger.debug "Sended to channel #{channel_name}"
    end
  end
end
