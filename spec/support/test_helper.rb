module Goliath
  module TestHelper
    # Make a Event Source request the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the DELETE request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def es_request(request_data = {}, errback = nil, &blk)
      path = request_data.delete(:path) || ''
      url = "http://localhost:#{@test_server_port}#{path}"
      source = EM::EventSource.new(url, request_data )
      source.message &blk if blk
      source.error { errback }
      source.start
    end
  end
end

