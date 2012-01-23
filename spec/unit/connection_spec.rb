require 'spec_helper'
require 'goliath/api'
require 'neighborparrot'
require 'eventmachine'

class DummyClient
  attr_accessor :queue, :broker, :env, :channel, :application
  include Neighborparrot::Connection

  def fake_current_brokers(brokers)
    @@channel_brokers = brokers
  end

  def fake_queue(queue)
    @@global_input_queue = queue
  end

  def input_queue_nil?
    @@global_input_queue.nil?
  end
end

describe Neighborparrot::Connection do

  before :each do
    @env = double('env').as_null_object
    @c = DummyClient.new
    @c.fake_queue nil
    @c.env = @env
    @c.application = factory_application @env
  end

  # prepare_connection
  #-----------------------------------------------
  describe 'prepare_connection' do
    let(:queue) { double('queue').as_null_object }
    before :each do
      @c.env.stub(:params) { { :channel => 'test'} }
      EM::Queue.stub(:new) { queue }
    end

    it 'should init connection queue' do
      @c.env.stub(:config) { { 'use_rabbit' => false }}
      init_stream = ": " << Array.new(2048, " ").join << "\n\n"
      queue.should_receive(:push).with(init_stream)
      @c.prepare_connection(@env)
    end

    it 'should subscribe to a channel' do
      @c.should_receive(:subscribe)
      @c.prepare_connection(@env)
    end
  end

  # init_queue
  #-----------------------------------------------

  describe 'init_queue' do
    it 'should create a new queue and configure to send to the client when receibe data' do
      msg = 'test msg'
      EM.run do
        @c.env.stub(:params) { {} } # EM Crazy errors
        @c.stub(:send_to_client) do |rec|
          rec.should eq msg
          schedule_em_stop
        end
        @c.init_queue
        @c.queue.push msg
        EM::Timer.new(1) { fail "Not received"; schedule_em_stop }
      end
    end
  end

  # subscribe
  #-----------------------------------------------

  describe 'subscribe' do
    before :each do
      @c.channel = 'test-channel'
    end

    it 'should subscribe the connection to the desired channel' do
      consumer_channel = double('consumer_channel')
      broker = double('broker').as_null_object
      broker.stub(:consumer_channel) { consumer_channel }

      @c.application.stub(:get_broker).with('test-channel') { broker }
      consumer_channel.should_receive(:subscribe)
      @c.subscribe
    end

    it 'should configure the subsciption for send to the connection messages from the channel' do
      EM.run do
        msg = 'test msg'
        real_channel = EM::Channel.new
        broker = double('broker').as_null_object
        broker.stub(:consumer_channel) { real_channel }
        @c.application.stub(:get_broker).with('test-channel') { broker }

        @c.stub(:send_to_client) do |rec|
          rec.should eq msg
          schedule_em_stop
        end
        @c.init_queue
        @c.subscribe
        real_channel.push msg
        EM::Timer.new(1) { fail "Not received"; schedule_em_stop }
      end
    end
  end

  # Send stuff
  #===============================================

  # prepare_send_request
  #-----------------------------------------------

  describe 'prepare_send_request' do
    before :each do
      @env = Goliath::Env.new
      @params = {}
      @env.stub(:params) { @params }
      @env.stub(:logger) { double('logger').as_null_object }
    end

    it 'should add event id if not present' do
      @c.should_receive(:generate_message_id)
      @c.prepare_send_request @env
    end

    it 'should mantain event_if if present' do
      @params['event_id'] = 1
      @c.should_not_receive(:generate_message_id)
      @c.prepare_send_request @env
    end

    it 'should send the the message to the input queue' do
      queue = double('queue')
      @c.fake_queue queue
      queue.should_receive(:push)# .with(@env)
      @c.prepare_send_request @env
    end

    it 'should return the new message id' do
      @c.stub(:generate_message_id) { 333 }
      @c.prepare_send_request(@env).should eq 333
    end
  end

  # send_to_broker
  #-----------------------------------------------

  describe 'send_to_broker' do
    before :each do
      @c.stub(:env) { double('env').as_null_object }
    end

    it 'should send a packed message to the application' do
      EM.run do
        msg = 'test message'
        event = { 'channel' => 'test', 'data' => 'test sting', 'event_id' => 1 }
        packed_msg = @c.pack_message_event event
        @c.application.stub(:send_message_to_channel) do |channel, msg|
          channel.should eq event['channel']
          msg.should eq packed_msg
          schedule_em_stop
        end
        @c.input_queue # EM Crazy errors
        @c.send_to_broker(event)
        EM::Timer.new(1) { fail "Not called";  schedule_em_stop }
      end
    end
  end

  # prepare_input_queue
  #-----------------------------------------------

  describe 'input_queue' do

    it 'should configure the queue to send messages to the broker when push' do
      EM.run do
        event = { :channel => 'test', :data => 'test sting', :event_id => 1 }
        @c.stub(:send_to_broker) do |received|
          received.should eq event
          schedule_em_stop
        end
        @c.input_queue.push event
        EM::Timer.new(1) { fail "Not called";  schedule_em_stop }
      end
    end
  end
end
