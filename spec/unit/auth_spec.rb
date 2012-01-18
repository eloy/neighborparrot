require 'spec_helper'
require 'neighborparrot'

class DummyAuth
  include Neighborparrot::Auth

  def env
    @env
  end
  def initialize
    @env = Goliath::Env
    @api_id = nil
    @api_key = nil
    @socket_id = nil
  end
end

describe Neighborparrot::Auth do
  before :each do
    @auth = DummyAuth.new
  end

  describe 'validate_connection_params' do
    it 'should fail without api_id' do
      @auth.env.stub(:params) { { } }
      expect { @auth.validate_params }.should raise_error
    end

    it 'should fail without socket_id' do
      @auth.env.stub(:params) { { 'api_id' => 'test' } }
      expect { @auth.validate_connection_params }.should raise_error
    end

    it 'should failt without connect_signature' do
      @auth.env.stub(:params) { { 'api_id' => 'test', 'socket_id' => '123456' } }
      expect { @auth.validate_connection_params }.should raise_error
    end

    it 'should failt without timestamp' do
      @auth.env.stub(:params) { { 'api_id' => 'test', 'socket_id' => '123456', 'connect_signature' => 'md5' } }
      expect { @auth.validate_connection_params }.should raise_error
    end

    it 'should pass with valid params' do
      @auth.env.stub(:params) { { 'api_id' => 'test', 'socket_id' => '123456', 'connect_signature' => 'md5', 'timestamp' => 1234 } }
      @auth.validate_connection_params
    end

  end

  describe 'auth_connection_request' do
    it 'should retribe app_info' do

    end
  end

  describe 'connection_string' do
    it 'should return api_id:socket_id:timestamp without channel' do
      params = { 'api_id' => 'test', 'socket_id' => '123456', 'connect_signature' => 'md5' , 'timestamp' => 123 }
      @auth.env.stub(:params) { params }
      @auth.validate_connection_params
      @auth.connection_string.should eq 'test:123456:123'
    end
  end
end
