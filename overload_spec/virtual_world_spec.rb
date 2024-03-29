require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'em-http-request'
require 'em-eventsource'

describe 'Virtual World' do
  before :all do
    @sent_count = 0
    @recv_count = 0
    @sent_error = 0
    @listen_error = 0
    @listen_expected = 0
    @recv_expected = 0
    @listeners = 0
    @channels = 0
    @send_url = 'https://neighborparrot.net:9000/send'
    @open_url = 'https://neighborparrot.net:9000/open'
    @test_length = 30
    # Message count is caculated based on test_length.
    # The broker need some more time to deliver
    @grace_time = 5

    @max_connections_without_errors = nil

    @world = generate_world @test_length

    @max_listeners = 100
  end

  it 'should create the world' do
    EventMachine.run do
      # For each chustomer
      @world.each do |customer|
        customer[:channels].each do |channel|
          @channels += 1
          @listen_expected = channel[:users]
          # Create a listener for each user
          for u in 1..channel[:users]
            EM.next_tick do
              @listeners += 1
              source = EM::EventSource.new(@open_url, :channel => channel[:id] )
              source.inactivity_timeout = 120
              source.message { @recv_count += 1 }
              source.error { @listen_error += 1 }
              source.start
            end

            # And create the delayed sender
            EM::PeriodicTimer.new(channel[:delay]) do
              http = EventMachine::HttpRequest.new(@send_url).post :body => { :channel => channel[:id], :data => 'Lorem Ipsumss' }
              http.callback do
                @sent_count += 1
                @recv_expected += channel[:users]
              end
              http.errback do
                @sent_error += 1
                # TODO: Only check listeners connection, but may be there are a lot of senders...
                if @max_connections_without_errors && @max_connections_without_errors <= @listeners
                  @max_connections_without_errors = @listeners
                end
              end
            end
          end
        end
      end

      # Setup a finish timer
      EM::Timer.new(@test_length + @grace_time) do
        rate = (@sent_count + @recv_count) / @test_length
        lost = @recv_expected - @recv_count
        buff = "Sent #{@sent_count}, received #{@recv_count}, "
        buff << "lost #{@recv_expected - @recv_count} "
        buff << "by #{@listeners} listeners in #{@channels} channels "
        buff << "in #{@test_length} seconds ~ #{rate} mps."
        puts buff
        error = ""
        refused = @listen_expected - @listeners
        error << "Listeners refused: #{refused}. " if refused > 0
        error << "Listeners errors: #{@listen_error}. " if @listen_error > 0
        puts error unless error.empty?
        EM.stop
      end
    end
  end

end
