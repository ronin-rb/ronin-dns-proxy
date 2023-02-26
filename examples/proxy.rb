#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'ronin/dns/proxy'

puts "Try running `host -p 2346 example.com 127.0.0.1` once the server is running."
puts

begin
  Ronin::DNS::Proxy.run('127.0.0.1', 2346) do |server|
    server.add_rule :A, 'example.com', '10.0.0.1'
    server.add_rule :AAAA, 'example.com', 'dead:beef::1'
  end
rescue Interrupt
  exit(127)
end
