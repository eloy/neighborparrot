require 'spec_helper'
require 'goliath/api'
require 'neighborparrot'

describe ConnectionHandler do
  before :each do
    @conn = ConnectionHandler.new
#    @conn = Class.new(ConnectionHandler)
    @env = Goliath::Env.new
  end

  describe 'Initializer' do
    it 'should prepare input queue' do
      ConnectionHandler.any_instance.should_receive(:prepare_input_queue)
      s = ConnectionHandler.new
    end
  end

  describe 'open' do
    it 'should create a new connection with valid values' do
      EM.run do
        Neighborparrot::Connection.stub(:new) do |env|
          env.should eq @env
          EM.stop
        end
        @conn.open @env
        EM::Timer.new(1) do
          fail "Not called"
          EM.stop
        end
      end
    end
    it 'should close the connection withoud api_id'
    it 'should close the connection without access signature'
  end

  describe 'send' do
    it 'should prepare the send request' do
      @conn.should_receive(:prepare_send_request).with(@env)
      @conn.send(@env)
    end

    it 'should close the connection withoud api_id'
    it 'should close the connection without send signature'
  end

  describe 'on_close' do
    it 'should close connection if exists' do
      connection = double('connection')
      @env['np_connection'] = connection
      connection.should_receive(:on_close)
      s = ConnectionHandler.new
      s.on_close @env
    end

    it 'should do nothing if no connection' do
      s = ConnectionHandler.new
      s.on_close @env
    end
  end
end
