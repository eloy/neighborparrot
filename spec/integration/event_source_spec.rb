require 'spec_helper'
require 'hmac-sha2'

describe 'Event source connection' do
  let(:err) {|error| Proc.new { fail "API request failed #{error}" } }

  # Event Source open
  #---------------------------------------------
  describe 'open' do
    it 'should open a connection with correct values' do
      init_stream = ": " << Array.new(2048, " ").join << "\n\n"
      app_info = factory_app_info
      request = factory_connect_request app_info
      with_api(Router, { :verbose => true, :log_stdout => true}) do
        mongo_db.collection('app_info').insert app_info # Store mongo fixature after start EM

        request_data = { :path => '/open', :query => request[:params], :keep_alive => true }
        aget_request(request_data, err) do |c|
          c.should eq init_stream
          EM.stop
        end
      end
    end

    it 'should receive messages' do
      init_stream = ": " << Array.new(2048, " ").join << "\n\n"
      test_msg = 'test message'
      app_info = factory_app_info
      post_body = { :channel => 'test',  :data => test_msg }
      request = factory_connect_request app_info
      with_api(Router, { :verbose => true, :log_stdout => true}) do
        mongo_db.collection('app_info').insert app_info # Store mongo fixature after start EM
        request_data = { :path => '/open', :query => request[:params], :keep_alive => true }
        aget_request(request_data, err) do |c|
          unless c.match '^:'
            c.should match test_msg
            EM.stop
          end
        end

        send_data = { :path => '/send', :body => sign_send_request(post_body, app_info) }
        apost_request(send_data, err)
      end
    end

    it 'should close the connection with incorrect values'
  end
end
