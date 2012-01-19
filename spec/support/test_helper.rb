require 'em-eventsource'
require 'neighborparrot'
require 'hmac-sha2'

module Goliath
  module TestHelper
    include Neighborparrot::Auth

    # Make a GET request asyncrony to the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the GET request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def aget_request(request_data = {}, errback = nil, &blk)
      req = test_request(request_data).aget(request_data)
      req.stream &blk
      # req.errback &errback if errback
      # req.errback { stop }
    end

    # Make a POST request the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the POST request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def apost_request(request_data = {}, errback = nil, &blk)
      req = test_request(request_data).apost(request_data)
    end
  end
end

def factory_app_info
  { :api_id => 'test-id', :api_key => '7ad3773142a6692b25b8' }
end

def factory_application(app_info=nil)
  app_info = factory_app_info if app_info.nil?
  app = Neighborparrot::Application.new app_info
  return app
end

def factory_connect_request(app_info=nil)
  app_info = factory_app_info if app_info.nil?
  timestamp = Time.new.utc.to_i
  socket_id = '23456'
  string = "test:123456:#{timestamp}"
  signature = HMAC::SHA256.hexdigest app_info[:api_key], string
  req = {
    :app_info => app_info,
    :socket_id => '123456',
    :timestamp => timestamp,
    :connection_string => string,
    :signature => signature,
    :params => {
      'api_id' => app_info[:api_id],
      'socket_id' => socket_id,
      'connect_signature' => signature ,
      'timestamp' => timestamp
    }
  }
  return req
end
