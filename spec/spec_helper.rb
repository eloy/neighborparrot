# $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
# $LOAD_PATH.unshift(File.dirname(__FILE__))
require 'bundler'

Bundler.setup
Bundler.require
require 'rspec'
require 'rack'
require 'rspec/mocks/standalone'
require 'goliath'
require 'goliath/test_helper'
require 'goliath/websocket'
require 'em-http-request'
require 'em-eventsource'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

Neighborparrot.stub(:env) { :test }

RSpec.configure do |c|
  c.include Goliath::TestHelper, :example_group => {
    :file_path => /spec\/integration/
  }

  # Need cleanup mongo database
  c.after do
    EM.synchrony do
      ['app_info'].each { |collection|  mongo_db.collection(collection).remove }
      EM.stop
    end
  end
end
