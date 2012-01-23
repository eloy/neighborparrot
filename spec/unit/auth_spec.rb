require 'spec_helper'
require 'neighborparrot'

class DummyAuth
  include Neighborparrot::Auth
  attr_accessor :api_id, :socket_id, :env, :application
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


  # valid_signature
  #-----------------------------------------------

  describe 'valid_signature?' do
    it 'should return false without signature' do
      app_info = factory_app_info
      @auth.application = Neighborparrot::Application.generate({ }, app_info)
      @auth.env = { 'REQUEST_METHOD' => 'GET', 'REQUEST_PATH' => '/open'}
      @auth.env.stub(:params) { { :channel => 'test' }}
      @auth.valid_signature?.should be_false
    end

    it 'should return false with invalid signature' do
      app_info = factory_app_info
      @auth.application = Neighborparrot::Application.generate({ }, app_info)
      @auth.env = { 'REQUEST_METHOD' => 'GET', 'REQUEST_PATH' => '/open'}
      signed = sign_connect_request({ :channel => 'test' }, { 'api_id' => app_info['api_id'], 'api_key' => 'other key'})
      @auth.env.stub(:params) { signed }
      @auth.valid_signature?.should be_false
    end

    it 'should return true with valid signature' do
      app_info = factory_app_info
      @auth.application = Neighborparrot::Application.generate({ }, app_info)
      @auth.env = { 'REQUEST_METHOD' => 'GET', 'REQUEST_PATH' => '/open'}
      signed = sign_connect_request({ :channel => 'test' }, app_info)
      @auth.env.stub(:params) { signed }
      @auth.valid_signature?.should be_true
    end

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

    it 'should pass with valid params' do
      @auth.env.stub(:params) { { 'auth_key' => 'test', 'socket_id' => '123456', 'signature' => 'md5', 'timestamp' => 1234 } }
      @auth.validate_connection_params
    end

    it 'should set instance vars' do
      @auth.env.stub(:params) { { 'auth_key' => 'test', 'socket_id' => '123456', 'signature' => 'md5', 'timestamp' => 1234 } }
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
        @auth.should_receive(:valid_signature?)
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
end
