require 'spec_helper'
require 'neighborparrot'

class DummyAuth
  include Neighborparrot::Auth
  attr_accessor :api_id, :socket_id
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
  before :all do
    @fake_app_info = { :api_id => 'test-app', :api_key => 'secret-key'}
  end

  before :each do
    @auth = DummyAuth.new
  end

  # validate_connection_params
  #-----------------------------------------------

  describe 'validate_connection_params' do
    it 'should fail without api_id' do
      @auth.env.stub(:params) { { } }
      expect { @auth.validate_params }.should raise_error
    end

    it 'should fail without socket_id' do
      @auth.env.stub(:params) { { 'api_id' => 'test' } }
      expect { @auth.validate_connection_params }.should raise_error
    end

    it 'should failt without signature' do
      @auth.env.stub(:params) { { 'api_id' => 'test', 'socket_id' => '123456' } }
      expect { @auth.validate_connection_params }.should raise_error
    end

    it 'should failt without timestamp' do
      @auth.env.stub(:params) { { 'api_id' => 'test', 'socket_id' => '123456', 'signature' => 'md5' } }
      expect { @auth.validate_connection_params }.should raise_error
    end

    it 'should pass with valid params' do
      @auth.env.stub(:params) { { 'api_id' => 'test', 'socket_id' => '123456', 'signature' => 'md5', 'timestamp' => 1234 } }
      @auth.validate_connection_params
    end

    it 'should set instance vars' do
      @auth.env.stub(:params) { { 'api_id' => 'test', 'socket_id' => '123456', 'signature' => 'md5', 'timestamp' => 1234 } }
      @auth.validate_connection_params
      @auth.api_id.should eq 'test'
      @auth.socket_id.should eq '123456'
    end
  end

  # auth_connection_request
  #-----------------------------------------------

  describe 'auth_connection_request' do
    describe 'with cached appication' do
      before :each do
        @app_info = factory_app_info
        @app = factory_application @auth.env, @app_info
        @request = factory_connect_request @app_info
        Neighborparrot::Application.stub(:get_application) { @app }
      end

      it 'should not look for app in mongo' do
        @auth.env.stub(:params) { Hash.new }
        @auth.stub(:valid_signature?) { true }
        @auth.api_id = @app.api_id
        Neighborparrot::Application.should_receive(:get_application).with(@app.api_id)
        @auth.should_not_receive(:mongo_first)
        @auth.auth_connection_request { }
      end

      it 'should check if valid signature' do
        @auth.env.stub(:params) { @request[:params] }
        @auth.stub(:valid_signature?) { true }
        @auth.stub(:connection_string) { @request[:connection_string] }
        @auth.should_receive(:valid_signature?).with(@request[:connection_string], @app.api_key, @request[:signature])
        @auth.auth_connection_request { }
      end

      it 'should call block if valid signature' do
        @auth.env.stub(:params) { Hash.new }
        @auth.stub(:valid_signature?) { true }
        @auth.should_not_receive(:mongo_first)
        auth = false
        @auth.auth_connection_request{ auth = true }
        auth.should be_true
      end

      it 'should raise error and not run block if invalid signature' do
        @auth.env.stub(:params) { Hash.new }
        @auth.stub(:valid_signature?) { false }
        @auth.should_not_receive(:mongo_first)
        auth = false
        expect { @auth.auth_connection_request{ auth = true } }.should raise_error
        auth.should be_false
      end
    end

    describe 'without cached appication' do
      before :each do
        @app_info = factory_app_info
        @app = factory_application @auth.env, @app_info
        @request = factory_connect_request @app_info
        Neighborparrot::Application.stub(:get_application) { nil }
      end

      it 'should retrive data from mongo db'
      it 'should check if valid signature'
      it 'should call block if valid signature'
      it 'should raise error and not run block if invalid signature'

    end
  end

  # validate_signature
  #-----------------------------------------------

  describe 'validate_signature' do
    it 'should validate a valid signature' do
      request = factory_connect_request
      @auth.valid_signature?(request[:connection_string], request[:app_info][:api_key], request[:signature]).should be_true
    end

    it 'should not validate an invalid signature' do
      request = factory_connect_request
      @auth.valid_signature?(request[:connection_string] + ".", request[:app_info][:api_key],  request[:signature]).should be_false
      @auth.valid_signature?(request[:connection_string], request[:app_info][:api_key]+".",  request[:signature]).should be_false
      @auth.valid_signature?(request[:connection_string], request[:app_info][:api_key],  request[:signature] + ".").should be_false
    end
  end

  # connection_string
  #-----------------------------------------------

  describe 'connection_string' do
    it 'should return api_id:socket_id:timestamp without channel' do
      params = { 'api_id' => 'test', 'socket_id' => '123456', 'signature' => 'md5' , 'timestamp' => 123 }
      @auth.env.stub(:params) { params }
      @auth.validate_connection_params
      @auth.connection_string.should eq 'test:123456:123'
    end
  end
end
