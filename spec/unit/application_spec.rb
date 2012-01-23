require 'spec_helper'

module Neighborparrot
  class Application
    def self.reset_applications
      @@applications = Hash.new
    end
  end
end


describe Neighborparrot::Application do
  after :each do
    Neighborparrot::Application.reset_applications
  end

  describe 'get_application' do
    it 'should call load_from_mongo if no application in cache' do
      Neighborparrot::Application.should_receive(:load_from_mongo).with('test')
      Neighborparrot::Application.get_application('test')
    end
  end

end
