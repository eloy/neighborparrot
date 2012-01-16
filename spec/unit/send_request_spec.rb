require 'spec_helper'
require 'goliath/api'
require 'neighborparrot'


module Neighborparrot
  @env = Goliath::Env.new

  def initialize
  end

  def env
    Goliath::Env.new
  end

  def fake_queue(queue)
    @@input_queue = queue
  end

  def fake_current_brokers(brokers)
    @@channel_brokers = brokers
  end

  def faker_prepare
    prepare_input_queue
  end

  def input_queue_nil?
    @@input_queue.nil?
  end

  def push_to_input_queue(event)
    @@input_queue.push event
  end
end

describe 'send_request' do
  describe 'prepare_send_request' do
    before :each do
      @env = Goliath::Env.new
      @params = {}
      @env.stub(:params) { @params }
      @s = ConnectionHandler.new
      @s.faker_prepare
    end

    it 'should add event id if not present' do
      @s.should_receive(:generate_message_id)
      @s.prepare_send_request @env
    end

    it 'should mantain event_if if present' do
      @params['event_id'] = 1
      @s.should_not_receive(:generate_message_id)
      @s.prepare_send_request @env
    end

    it 'should send the the message to the input queue' do
      queue = double('queue')
      @s.fake_queue queue
      queue.should_receive(:push)# .with(@env)
      @s.prepare_send_request @env
    end

    it 'should return the new message id' do
      @s.stub(:generate_message_id) { 333 }
      @s.prepare_send_request(@env).should eq 333
    end
  end

  describe 'send_to_broker' do
    before :each do
      @s = ConnectionHandler.new
      @s.stub(:env) { double('env').as_null_object }
      @s.fake_current_brokers Hash.new
    end

    it 'should return nil if desired broker don not exist' do
      @s.send_to_broker(:channel => 'invalid').should be_nil
    end

    it 'should send a packed message to the broker' do
      EM.run do
        msg = 'test message'
        event = { :channel => 'test', :data => 'test sting', :event_id => 1 }
        packed_msg = @s.pack_message_event event
        fake_channel = double('channel_broker')
        fake_channel.stub(:publish) do |msg|
          msg.should eq packed_msg
        EM.stop
        end
        brokers = { 'test' => fake_channel }
        @s.stub(:env) { double('env').as_null_object }
        @s.fake_current_brokers brokers
        @s.send_to_broker(event).should_not be_nil
        EM::Timer.new(1) { fail "Not called";  EM.stop }
      end
    end
  end

  describe 'prepare_input_queue' do
    before :each do
      @s = ConnectionHandler.new
    end
    it 'should instantiate the queue' do
      @s.faker_prepare
      @s.input_queue_nil?.should be_false
    end

    it 'should configure the queue to send messages to the broker when push' do
      EM.run do
        @s.faker_prepare
        event = { :channel => 'test', :data => 'test sting', :event_id => 1 }
        @s.stub(:send_to_broker) do |received|
          received.should eq event
          EM.stop
        end
        @s.push_to_input_queue event
        EM::Timer.new(1) { fail "Not called";  EM.stop }
      end
    end
  end

end
