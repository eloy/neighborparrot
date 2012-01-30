require 'hmac-sha2'
require 'signature'

module Neighborparrot
  class AuthError < Goliath::Validation::BadRequestError
    def initialize(env,msg)
      super(msg)
      env.logger.debug "Error #{msg}"
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
      raise AuthError.new(env, "api_id is mandatory") if @api_id.nil?
      raise AuthError.new(env, "no signature") unless env.params['auth_signature']
    end

    # Ensure valid send params and
    # put into instance vars.
    # Called from SendRequestEndPoint
    def validate_send_params
      @api_id = env.params['auth_key']
      @data = env.params['data']
      raise AuthError.new(env, "api_id is mandatory") if @api_id.nil?
      raise AuthError.new(env, "data is mandatory") if @data.nil?
      raise AuthError.new(env, "no signature") unless env.params['auth_signature']
    end

    # Check authorization
    # retrive application information and
    # exec block code if the request have a valid signature
    def auth_request(&blk)
      @application = Neighborparrot::Application.get_application @api_id
      mongo_req = mongo_first('app_info', :api_id => @api_id)
      mongo_req.callback do |app_info|
        if app_info && valid_signature?(app_info)
          blk.call @application
        else
          env.logger.debug "Bad login. Obtained app_info #{app_info} #{env.params}"
          login_failed
        end
      end
    end
  end
end
