require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
Dir["#{File.dirname(__FILE__)}/../../lib/**/*.rb"].each {|f| require f}

describe "Broker" do
  include Goliath::TestHelper
end
