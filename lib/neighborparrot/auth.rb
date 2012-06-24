require 'hmac-sha2'
require 'signature'

module Neighborparrot
  class AuthError < Goliath::Validation::BadRequestError
    include Neighborparrot::Logger
    def initialize(msg)
      super(msg)
      logger.debug "Error #{msg}"
    end
  end

  # Auth module.
  module Auth
    include Neighborparrot::Mongo
    attr_reader :presence_info

    # Return a unix UTC timestamp
    def current_timestamp
      Time.new.utc.to_i
    end

    # Generate a valid uuid string
    def generate_uuid
      UUIDTools::UUID.random_create.to_s
    end

    # Return true if valid signature
    def valid_signature?(app_info)
      token = Signature::Token.new(app_info['api_id'], app_info['api_key'])
      path = env["REQUEST_PATH"]
      method = path == '/open' ? 'GET' : env["REQUEST_METHOD"] # ES Polyfill require POST
      request = Signature::Request.new(method, path, env.params)
      request.authenticate_by_token token, nil
    end

    # Ensure valid connection params and
    # put it into instance vars. Called from EventSourceEndPoint
    # and WebSocketEndPoint in response
    def validate_connection_params
      @api_id = env.params['auth_key']

      # Setup presence values althought presence not enabled
      # This will generate a unique-uuid for each connection
      presence_user_id = env.params['presence_user_id'] || "*#{generate_uuid}*"
      presence_data = env.params['presence_data']
      presence_invisible = env.params['presence_invisible'] == 'true'
      @presence_info = { :user_id => presence_user_id, :data => presence_data, :invisible => presence_invisible }

      raise AuthError.new("api_id is mandatory") if @api_id.nil?
      raise AuthError.new("no signature") unless env.params['auth_signature']
    end

    # Ensure valid send params and
    # put it into instance vars.
    # Called from SendRequestEndPoint
    def validate_send_params
      @api_id = env.params['auth_key']
      @data = env.params['data']
      @channel = env.params['channel']
      raise AuthError.new("api_id is mandatory") if @api_id.nil?
      raise AuthError.new("data is mandatory") if @data.nil?
      raise AuthError.new("channel is mandatory") if @channel.nil?
      raise AuthError.new("no signature") unless env.params['auth_signature']
    end

    # Should be called in Synchrony
    def authenticate
      # Retrive data for auth
      app_info = mongo_db.collection('app_info').first(:api_id => @api_id)

      pp app_info

      if app_info && valid_signature?(app_info)
        @application = Neighborparrot::Application.get_application app_info
        # @application.app_info = app_info
        @authenticated = true
        logger.debug "LOGIN OK"
        return true
      end
      logger.debug "LOGIN FAILED for #{@api_id}"
      return false
    end
  end
end
