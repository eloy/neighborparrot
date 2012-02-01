# Logger helper
module Neighborparrot
  module Logger
    def self.logger
      Log4r::Logger['goliath']
    end
    def logger
      Log4r::Logger['goliath']
    end
  end
end
