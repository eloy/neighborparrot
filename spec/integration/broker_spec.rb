require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
Dir["#{File.dirname(__FILE__)}/../../lib/**/*.rb"].each {|f| require f}

describe Broker do
  include Goliath::TestHelper

  let(:err) { Proc.new { fail 'Api request fail'}}

  it 'should connect to the broker' do
    with_api(Broker) do
      post_request({:path => '/open', :query => { :channel => 'test'} }, err) do |c|
        puts c.response
      end
    end
  end
end
