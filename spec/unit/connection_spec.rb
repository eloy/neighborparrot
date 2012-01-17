require 'spec_helper'
require 'goliath/api'
require 'neighborparrot'
require 'eventmachine'

describe Neighborparrot::Connection do
  let(:env) { double('env').as_null_object }

  describe 'initialize' do
    let(:queue) { double('queue').as_null_object }
    before :each do
      env.stub(:params) { { :channel => 'test'} }
      EM::Queue.stub(:new) { queue }
    end

    it 'should init connection queue' do
      init_stream = ": " << Array.new(2048, " ").join << "\n\n"
      queue.should_receive(:push).with(init_stream)
      Neighborparrot::Connection.new(env)
    end

    it 'should subscribe to a channel' do
      Neighborparrot::Connection.any_instance.should_receive(:subscribe)
      Neighborparrot::Connection.new(env)
    end
  end

  describe 'init_queue' do
    before :each do
      module Neighborparrot

        class Connection
          attr_accessor :queue
          def initialize(env)
          end
        end
      end
    end

    it 'should create a new queue and configure to send to the client when receibe data' do
      msg = 'test msg'
      EM.run do
        c = Neighborparrot::Connection.new(env)
        c.stub(:send_to_client) do |rec|
          rec.should eq msg
          EM.stop
        end
        c.init_queue
        c.queue.push msg
        EM::Timer.new(1) { fail "Not received"; EM.stop }
      end
    end
  end

  describe 'subscribe' do
    before :each do
      module Neighborparrot
        class Connection
          attr_accessor :queue, :broker
          def initialize(env)
            @env = env
            @channel = 'test-channel'
          end
        end
      end

    end

    it 'should subscribe the connection to the desired channel' do
      consumer_channel = double('consumer_channel')
      broker = double('broker').as_null_object
      broker.stub(:consumer_channel) { consumer_channel }

      c = Neighborparrot::Connection.new(env)
      c.stub(:get_channel).with(env, 'test-channel') { broker }
      consumer_channel.should_receive(:subscribe)
      c.subscribe
    end

    it 'should configure the subsciption for send to the connection messages from the channel' do
      EM.run do
        msg = 'test msg'
        c = Neighborparrot::Connection.new(env)
        real_channel = EM::Channel.new
        broker = double('broker').as_null_object
        broker.stub(:consumer_channel) { real_channel }
        c = Neighborparrot::Connection.new(env)
        c.stub(:get_channel).with(env, 'test-channel') { broker }

        c.stub(:send_to_client) do |rec|
          rec.should eq msg
          EM.stop
        end
        c.init_queue
        c.subscribe
        real_channel.push msg
        EM::Timer.new(1) { fail "Not received"; EM.stop }
      end

    end

  end

end
