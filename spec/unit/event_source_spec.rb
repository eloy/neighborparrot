require 'spec_helper'
require 'neighborparrot'

class EventSourceEndPoint
  attr_accessor :api_id, :socket_id
end

describe EventSourceEndPoint do
  before :each do
    @env = double('env').as_null_object
    @es = EventSourceEndPoint.new
    @es.stub(:auth_connection_request) { double('auth_connection_request').as_null_object }
  end

  describe 'respone' do
    it 'should call validate params' do
      @env.stub(:params) { { 'a' => 'a'}}
      @es.should_receive(:validate_connection_params).with(@env.params)
      @es.response @env
    end

    it 'should call auth_connection_request' do
      @env.stub(:params) { { 'a' => 'a'}}
      @es.stub(:validate_connection_params) { true }
      @es.should_receive(:auth_connection_request)
      @es.response @env
    end
  end
end
