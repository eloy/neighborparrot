require 'hmac-sha2'
module Neighborparrot
  module Auth
    include Neighborparrot::Mongo

    def generate_socket_id
      return '12345678'
    end

    # Return a unix UTC timestamp
    def current_timestamp
      Time.new.utc.to_i
    end

    def valid_signature?
      token = Signature::Token.new(@application.api_id, @application.api_key)
      request = Signature::Request.new(env["REQUEST_METHOD"], env["REQUEST_PATH"], env.params)
      request.authenticate_by_token token
    end

    # Ensure valid connection params and
    # put into instance vars. Called from EventSourceEndPoint
    # and WebSocketEndPoint in response
    def validate_connection_params
      @api_id = env.params['auth_key']
      @socket_id = env.params['socket_id']
      raise Goliath::Validation::BadRequestError.new("api_id is mandatory") if @api_id.nil?
      raise Goliath::Validation::BadRequestError.new("socket_id is mandatory") if @socket_id.nil?
    end

    # Ensure valid send params and
    # put into instance vars.
    # Called from SendRequestEndPoint
    def validate_send_params
      @api_id = env.params['auth_key']
      @data = env.params['data']
      raise Goliath::Validation::BadRequestError.new("api_id is mandatory") if @api_id.nil?
      raise Goliath::Validation::BadRequestError.new("data is mandatory") if @data.nil?
      raise Goliath::Validation::BadRequestError.new("no signature") unless env.params['signature']
      raise Goliath::Validation::BadRequestError.new("no timestamp") unless env.params['timestamp']
      #todo raise if invalid timestamp
    end

    # Check authorization
    # retrive application information and
    # exec block code if the request have a valid signature
    def auth_connection_request(&blk)
      signature = env.params['signature']
      @application = Neighborparrot::Application.get_application @api_id
      # If cached app use it
      if @application
        raise Goliath::Validation::BadRequestError.new("invalid signature") unless valid_signature?
        blk.call @application
        return
      end
      # Asyc create the application
      resp = mongo_first 'app_info', { :api_id => @api_id }
      resp.callback do |app_info|
        raise Goliath::Validation::BadRequestError.new("invalid application") unless app_info
        @application = Neighborparrot::Application.generate env, app_info
        # Check auth
        raise Goliath::Validation::BadRequestError.new("invalid signature") unless valid_signature?
        blk.call @application
      end
    end
  end
end
