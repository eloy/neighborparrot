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
end
