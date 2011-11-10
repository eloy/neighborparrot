#!/usr/bin/env ruby
require "uri"
require "net/http"
require "json"

params = {:room => 'prueba', :id => `uuidgen`.strip, :data => "Hello World"}
x = Net::HTTP.post_form(URI.parse('http://localhost:9000/send'), params)
puts x.body
