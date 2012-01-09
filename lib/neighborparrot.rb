#!/usr/bin/env ruby

require 'rack'
require 'rack/multipart'
require 'rack/multipart/parser'
require "rubygems"
require 'goliath'



module Neighborparrot
  USE_RABBITMQ = false
end

require 'neighborparrot/protocol'
require 'neighborparrot/index_template'
require 'neighborparrot/brokers/test_channel_broker'
require 'neighborparrot/brokers/channel_broker'
require 'neighborparrot/channel_broker_factory'

#require 'neighborparrot/brokers/amqp_channel_broker'

require 'neighborparrot/connection'
require 'neighborparrot/send_request'
require 'neighborparrot/connection_handler'
