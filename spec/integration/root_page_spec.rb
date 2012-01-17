require 'spec_helper'

describe 'Root request' do
  let(:err) {|error| Proc.new { fail "API request failed #{error}" } }

  before :all do
  end


  describe 'invalid connections' do
    it 'shound deny invalids paths' do
      with_api(ConnectionHandler, :log_stdout => true) do
        request_data = { :path => '/moco', :query => { :api_id => 'test' } }
        get_request(request_data, err) do |c|
          c.response_header.status.should eq 404
        end
      end
    end
  end

  # index.html
  #---------------------------------------------
  describe 'index.html' do
    it 'shound allow incoming connections with correct params' do
      with_api(ConnectionHandler) do
        request_data = { :path => '/', :query => {:api_id => 'test'} }
        get_request(request_data, err) do |c|
          c.response.should match ':-\)'
          c.response.should match 'https://neighborparrot.com/js/broker.js'
          c.response.should_not match 'https://neighborparrot.com/js/eventsource.js'
          stop
        end
      end
    end

    it 'should add polyfill if requested' do
      with_api(ConnectionHandler) do
        request_data = { :path => '/', :query => {:api_id => 'test', :use_polyfill => 'true' } }
        get_request(request_data, err) do |c|
          c.response.should match 'https://neighborparrot.com/js/eventsource.js'
          stop
        end
      end
    end
  end
end
