require 'hmac-sha2'

module Neighborparrot
  module Auth
    include Neighborparrot::Mongo

    def generate_socket_id
      return '12345678'
    end

    # Ensure valid connection params and
    # put into instance vars. Called from EventSourceEndPoint
    # and WebSocketEndPoint in response
    def validate_connection_params
      @api_id = env.params['api_id']
      @socket_id = env.params['socket_id']
      raise Goliath::Validation::BadRequestError.new("api_id is mandatory") if @api_id.nil?
      raise Goliath::Validation::BadRequestError.new("socket_id is mandatory") if @socket_id.nil?
      raise Goliath::Validation::BadRequestError.new("invalid signature") unless env.params['connect_signature']
      raise Goliath::Validation::BadRequestError.new("invalid signature") unless env.params['timestamp']
      #todo raise if invalid timestamp
    end

    # Check authorization
    # retrive application information and
    # exec block code if the request have a valid signature
    def auth_connection_request(&blk)
      signature = connection_signature = env.params['connect_signature']
      @application = Neighborparrot::Application.get_application @api_id
      # If cached app use it
      if @application
        valid = valid_signature? connection_string, @application.api_key, signature
        raise Goliath::Validation::BadRequestError.new("invalid signature") unless valid
        blk.call @application
        return
      end
      # Asyc create the application
      resp = mongo_first 'app_info', { :api_id => @api_id }
      resp.callback do |app_info|
        raise Goliath::Validation::BadRequestError.new("invalid signature") unless app_info
        @application = Neighborparrot::Application.generate app_info

        # Check auth
        valid = valid_signature? connection_string, @application.api_key, signature
        raise Goliath::Validation::BadRequestError.new("invalid signature") unless valid
        blk.call @application
      end
    end

    # Create a connection string with this format
    # api_id:socket_id:timestamp
    def connection_string
      timestamp = env.params['timestamp']
      str = [@api_id, @socket_id, timestamp].join ':'
    end

    # Generate a valid signature
    def create_signature(string, api_key)
      HMAC::SHA256.hexdigest api_key, string
    end

    # Return a unix UTC timestamp
    def current_timestamp
      Time.new.utc.to_i
    end

    # check string signature
    def valid_signature?(string, api_key, signature)
      create_signature(string, api_key) == signature
    end
  end
end
