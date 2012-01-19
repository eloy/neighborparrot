module Neighborparrot

  # Customer application model
  # Mantain application data, channels and users
  # store persistent data like max connections and in mongodb
  class Application

    attr_reader :api_id, :api_key

    # Global application Hash.
    # Contains all the application instances indexed by api_id
    @@applications = Hash.new

    # Return the application with desired api_id
    # Create new record from mongo data if not loaded
    # or nil if api_id do not correspond with any app
    # @param [String] api_id
    # @return [Application] application
    def self.get_application(api_id)
      @@applications[api_id]
    end

    def self.generate(app_info)
      return false unless app_info
      app = Application.new(app_info)
      @@applications[app.api_id] = app
      app
    end

    def initialize(app_info)
      @app_info = app_info
      @api_id = @app_info[:api_id]
      @api_key = @app_info[:api_key]
    end
  end
end
