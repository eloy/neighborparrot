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
    # return true if success. Error is raised otherwise
    def auth_connection_request(&blk)
      @app_info = Neighborparrot::Application.get_application @api_id
      if @app_info
        validate_signature
        blk.call resp
      end
      resp = mongo_first 'app_info', { :api_id => @api_id }
      resp.callback do |app_info|
        raise Goliath::Validation::BadRequestError.new("invalid signature") unless app_info
        @app_info = Neighborparrot::Application.generate app_info

        # Check auth
        blk.call resp
      end
    end

    def connection_string
      timestamp = env.params['timestamp']
      str = [@api_id, @socket_id, timestamp].join ':'
    end

    private
    # check string signature
    def valid_signature(string, api_key)
      connection_signature = env.params['connection_signature']
    end
  end
end
