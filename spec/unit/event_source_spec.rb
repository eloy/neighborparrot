require 'spec_helper'
require 'neighborparrot'

class EventSourceEndPoint
  attr_accessor :api_id, :socket_id
end

describe EventSourceEndPoint do
  before :each do
    @env = double('env').as_null_object
    @es = EventSourceEndPoint.new
  end

  describe 'respone' do
    it 'should call validate params' do
      @env.stub(:params) { { 'a' => 'a'}}
      @es.should_receive(:validate_connection_params).with(@env.params)
      @es.response @env
    end

    it 'should check signature for authorization' do
      @env.stub(:params) { { 'a' => 'a'}}
      @es.stub(:validate_connection_params) { true }
      @es.should_receive(:validate_connection_params)
      @es.response @env
    end
  end
end
