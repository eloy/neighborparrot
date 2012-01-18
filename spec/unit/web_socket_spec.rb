require 'spec_helper'
require 'neighborparrot'

class WebSocketEndPoint
  attr_accessor :api_id, :socket_id
end


describe WebSocketEndPoint do

  before :each do
    @env = double('env').as_null_object
    @ws = WebSocketEndPoint.new
  end

  describe 'on_open' do
    it 'should call validate params' do
      @env.stub(:params) { { 'a' => 'a'}}
      @ws.should_receive(:validate_connection_params).with(@env.params)
      @ws.on_open @env
    end
  end
end

