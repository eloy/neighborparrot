require 'hmac-sha2'
require 'signature'

module Neighborparrot
  class AuthError < Goliath::Validation::BadRequestError
    include Neighborparrot::Logger
    def initialize(env,msg)
      super(msg)
      logger.debug "Error #{msg}"
    end
  end
  module Auth
    include Neighborparrot::Mongo
    attr_reader :presence_data

    # Return a unix UTC timestamp
    def current_timestamp
      Time.new.utc.to_i
    end

    def valid_signature?(app_info)
      token = Signature::Token.new(app_info['api_id'], app_info['api_key'])
      request = Signature::Request.new(env["REQUEST_METHOD"], env["REQUEST_PATH"], env.params)
      request.authenticate_by_token token
    end

    # Ensure valid connection params and
    # put into instance vars. Called from EventSourceEndPoint
    # and WebSocketEndPoint in response
    def validate_connection_params
      @api_id = env.params['auth_key']
      raise AuthError.new("api_id is mandatory") if @api_id.nil?
      raise AuthError.new("no signature") unless env.params['auth_signature']
    end

    # Ensure valid send params and
    # put into instance vars.
    # Called from SendRequestEndPoint
    def validate_send_params
      @api_id = env.params['auth_key']
      @data = env.params['data']
      raise AuthError.new("api_id is mandatory") if @api_id.nil?
      raise AuthError.new("data is mandatory") if @data.nil?
      raise AuthError.new("no signature") unless env.params['auth_signature']
    end

    # Should be called in Synchrony
    def authenticate
      @application = Neighborparrot::Application.get_application @api_id
      app_info = mongo_db.collection('app_info').first(:api_id => @api_id)
      if app_info && valid_signature?(app_info)
        @application.app_info = app_info
        logger.debug "LOGIN OK"
        return true
      end
      logger.debug "Bad login for application_id#{app_info['application_id']}"
      return false
    end
  end
end
