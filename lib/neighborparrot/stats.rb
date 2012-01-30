module Neighborparrot
  module Stats

    # Inialize stats for current application
    def initialize_stats
      @current_connections = 0
      @max_connections = 0
      @current_channels = Hash.new
      @max_channels = 0
    end

    def stat_connection_open
      @current_connections += 1
      if @current_connections > @max_connections
        @max_connections = @current_connections
        # TODO Log max connections
      end
      # log connection open
      # send to live stream
    end

  end
end
