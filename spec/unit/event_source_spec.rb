require 'spec_helper'
require 'neighborparrot'

class EventSourceEndPoint
  attr_accessor :api_id, :socket_id
end

describe EventSourceEndPoint do
  before :each do
    @env = double('env').as_null_object
    @es = EventSourceEndPoint.new
    @es.stub(:auth_request) { double('auth_request').as_null_object }
  end

  describe 'respone' do
    it 'should call validate params' do
      @env.stub(:params) { { 'a' => 'a'}}
      @es.should_receive(:validate_connection_params)
      @es.response @env
    end

    it 'should call auth_connection_request'
  end
end
