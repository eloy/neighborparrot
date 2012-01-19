require 'spec_helper'

describe 'Event source connection' do
  let(:err) {|error| Proc.new { fail "API request failed #{error}" } }

  # Event Source open
  #---------------------------------------------
  describe 'open' do
    it 'should open a connection with correct values' do
      init_stream = ": " << Array.new(2048, " ").join << "\n\n"
      with_api(Router, { :verbose => true, :log_stdout => true}) do
        request_data = { :path => '/open', :query => { :channel => 'test' }, :keep_alive => true }
        aget_request(request_data, err) do |c|
          c.should eq init_stream
          EM.stop
        end
      end
    end

    it 'should receive messages' do
      init_stream = ": " << Array.new(2048, " ").join << "\n\n"
      test_msg = 'test message'
      with_api(Router, { :verbose => true, :log_stdout => true}) do
        request_data = { :path => '/open', :query => { :channel => 'test' }, :keep_alive => true }
        aget_request(request_data, err) do |c|
          unless c.match '^:'
            c.should match test_msg
            EM.stop
          end
        end

        send_data = { :path => '/send', :body => { :channel => 'test', :data => test_msg  } }
        apost_request(send_data, err)
      end
    end

    it 'should close the connection with incorrect values'
  end
end
