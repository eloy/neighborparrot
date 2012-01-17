require 'em-eventsource'
module Goliath
  module TestHelper
    # # Make a Event Source request the currently launched API.
    # #
    # # @param request_data [Hash] Any data to pass to the DELETE request.
    # # @param errback [Proc] An error handler to attach
    # # @param blk [Proc] The callback block to execute
    # def es_request(request_data = {}, errback=nil)
    #   path = request_data.delete(:path) || ''
    #   url = "http://localhost:#{@test_server_port}#{path}"
    #   puts request_data[:query]
    #   source = EM::EventSource.new(url, request_data[:query] )
    #  source.inactivity_timeout = 2
    #   source.message &blk if blk
    #   source.error { errback }
    #   return source
    # end



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

