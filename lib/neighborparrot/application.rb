require 'pp'
module Neighborparrot

  # Customer application model
  # Mantain application data, channels and users
  # store persistent data like max connections and in mongodb
  class Application
    include Neighborparrot::Stats
    include Neighborparrot::Logger

    attr_accessor :api_id, :app_info, :channels

    # Global application Hash.
    # Contains all the application instances
    # indexed by api_id
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
    # stop timers, flush stats and remove
    # from current_applications
    def destroy
      stop_stats
      @@applications.delete @api_id
    end

    # Subscribe the endpoint to desired channel
    # and perform the block with the msg as arg.
    # If application has presence enabled, send the
    # connect event to other peers and send the current
    # users to the new connection.
    # @return [int] subscription_id for later disconnect
    def subscribe(endpoint, channel_name, &block)
      channel = get_channel(channel_name)
      subscription_id = channel.subscribe(endpoint, block)

      # Send presence events if configured
      if @app_info['presence']
        EM.defer { fire_presence_open_events endpoint, channel }
      end

      return subscription_id
    end

    # Unsubscribe connection from channel
    # Remove channel if no more users connected
    # Remove application if no more apps
    def unsubscribe(endpoint, channel_name, subscription_id)
      channel = @channels[channel_name]
      if channel
        channel.unsubscribe(subscription_id)
        EM.next_tick { cleanup_after_unsubscribe channel }
        # Fire presence events if configured
        if @app_info['presence']
          EM.defer { fire_presence_close_events endpoint, channel }
        end

      else
        logger.debug "Trying to unsubscribe for an inexistant channel #{channel_name}"
      end
    end

    # Send the presence open events to the current channel users
    # and send the current user list to the new connection
    def fire_presence_open_events(endpoint, channel)
      channel_name = channel.name
      presence_info = endpoint.presence_info
      already_logged = channel.subscriptions_for(presence_info[:user_id]).length > 1
      invisible = presence_info[:invisible]
      # Send the connection open to other peers
      unless already_logged || invisible
        channel.publish presence_message_generate(channel_name, 'open', presence_info)
      end

      # And send to this peer other connections status
      channel.unique_subscriptors.each do |s|
        if (s[:user_id] != presence_info[:user_id] && !s[:invisible]) || already_logged
          endpoint.send_to_client presence_message_generate(channel_name, 'current', s)
        end
      end
    end

    # Send the presence close events to the current channel users
    # and fire the close web callback if configured
    def fire_presence_close_events(endpoint, channel)
      channel_name = channel.name
      presence_info = endpoint.presence_info
      already_logged = channel.subscriptions_for(presence_info[:user_id]).length > 0

      # Send the connection close to other peers
      unless already_logged || presence_info[:invisible]
        channel.publish presence_message_generate(channel_name, 'close', presence_info)
        # TODO: fire web callbacks
      end
    end

    # Generate a presence open mesage
    def presence_message_generate(channel_name, action, subscriptor)
      presence_channel = "#{channel_name}-presence"
      a = { :channel => presence_channel,
        :data => {
          :user_id => subscriptor[:user_id],
          :action => action,
          :data => subscriptor[:data]
        }
      }
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
