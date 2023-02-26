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

    # return multiple values
    server.add_rule :A, 'ftp.example.com', ['10.0.0.42', '10.0.0.43']

    # match a query using a regex
    server.add_rule :TXT, /^spf\./, "v=spf1 include:10.0.0.1 ~all"

    # return an error for a valid hostname
    server.add_rule :A, 'updates.example.com', :ServFail

    # define a dynamic rule
    server.add_rule :CNAME, /^www\./, ->(type,name,transaction) {
      # append '.hax' to the domain name
      names = name.split('.').push('hax')

      transaction.respond!(names)
    }
  end
rescue Interrupt
  exit(127)
end
