module Neighborparrot
  module Stats
    include Neighborparrot::Mongo
    include Neighborparrot::Logger

    # Inialize stats for current application
    def initialize_stats
      @total_connections = 0
      @current_connections = 0
      @max_connections = 0
      @current_channels =
      @max_channels = 0
      @current_messages = Hash.new()
      create_push_timer
      logger.debug "Stats init for application"
    end

    def stop_stats
      @push_timer.cancel
      push_stats
    end

    def create_push_timer
      @push_timer = EM::PeriodicTimer.new(Neighborparrot::PUSH_STATS_FREC) do
        push_stats
      end
    end

    # Stat a new connection
    def stat_connection_open
      @total_connections += 1
      @current_connections += 1
      if @current_connections > @max_connections
        @max_connections = @current_connections
      end
      # send to live stream
    end

    def stat_connection_close
      @current_connections -= 1
      # send to live stream
    end

    def stat_channel_created(channel)
      @current_channels += 1
      if @current_channels > @max_channels
        @max_channels = @current_channels
      end
      # send to live stream
    end

    def stat_channel_destroyed(channel)
      @current_channels -= 1
      #log channel destroyed
    end

    def stat_message_sended(channel)
      @current_messages[channel] = { :send => 0, :recv => 0 } unless @current_messages[channel]
      @current_messages[channel][:send] += 1
      # send to live stream
    end

    def stat_message_received(channel, count)
      @current_messages[channel] = { :send => 0, :recv => 0 } unless @current_messages[channel]
      @current_messages[channel][:recv] += count
      # send to live stream
    end

    # Store stats in mongo and reset counters
    def push_stats
      logger.debug "Pushing stats"
      base = base_stats
      conn_stats = base.merge(:conn => @total_connections, :max_conn => @max_connections, :chan => @max_channels)
      msg_stats = []
      @current_messages.each do |key, s|
        channels_stats = base.merge(:channel => key, :send => s[:send], :recv => s[:recv])
        msg_stats.push channels_stats
      end
      mongo_db.collection('stats_conn').insert conn_stats
      mongo_db.collection('stats_msg').insert msg_stats
      reset
    end

    def base_stats
      date = Time.new()
      { :date => date,
        :server => HOSTNAME,
        :account_id => @app_info['account_id'],
        :application_id => @app_info['application_id']
      }
    end

    def reset
      @total_connections = 0
      @current_messages = Hash.new
      @max_channels = @current_channels
      @max_connections = @current_connections
    end
  end
end
