require 'em-eventsource'
require 'neighborparrot'
require 'hmac-sha2'

module Goliath
  module TestHelper

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
      return req
    end

    # Make a POST request the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the POST request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def apost_request(request_data = {}, errback = nil, &blk)
      req = test_request(request_data).apost(request_data)
      req.errback &errback if errback
      return req
    end
  end
end

include Neighborparrot::Auth

def schedule_em_stop
  EM.next_tick { EM.stop }
end

def factory_app_info
  api_id =  UUIDTools::UUID.random_create.to_s
  api_key =  UUIDTools::UUID.random_create.to_s
  info = { 'api_id' => api_id, 'api_key' => api_key }
end

def factory_application(env, app_info=nil)
  app_info = factory_app_info if app_info.nil?
  Neighborparrot::Application.any_instance.stub(:create_push_timer) { true }
  Neighborparrot::Application.any_instance.stub(:logger) { double('logger').as_null_object }
  app = Neighborparrot::Application.new(app_info['api_id'])
  return app
end

def factory_connect_request(app_info=nil, channel='test')
  app_info = factory_app_info if app_info.nil?
  socket_id = UUIDTools::UUID.random_create.to_s
  params = {
    'socket_id' => socket_id,
    'channel' => channel
  }

  req = {
    :app_info => app_info,
    :socket_id => socket_id,
    :params => sign_connect_request(params, app_info)
  }
  return req
end



def sign_connect_request(params, app_info)
  sign_request('GET', '/open', params, app_info)
end

def sign_send_request(params, app_info)
  sign_request('POST', '/send', params, app_info)
end

def sign_request(method, path, params, app_info)
  token = Signature::Token.new(app_info['api_id'], app_info['api_key'])
  request = Signature::Request.new(method, path, params)
  auth_hash = request.sign(token)
  params.merge(auth_hash)
end
