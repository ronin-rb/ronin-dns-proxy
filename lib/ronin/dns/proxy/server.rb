# frozen_string_literal: true
#
# ronin-dns-proxy - A DNS server and proxy library.
#
# Copyright (c) 2023-2024 Hal Brodigan (postmodern.mod3@gmail.com)
#
# ronin-dns-proxy is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ronin-dns-proxy is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with ronin-dns-proxy.  If not, see <https://www.gnu.org/licenses/>.
#

require 'ronin/dns/proxy/rule'
require 'ronin/support/network/dns'

require 'async/dns'

module Ronin
  module DNS
    module Proxy
      #
      # A rule based DNS proxy server.
      #
      class Server < Async::DNS::Server

        # The host the server will listen on.
        #
        # @return [String]
        attr_reader :host

        # The port the server will listen on.
        #
        # @return [Integer]
        attr_reader :port

        # The upstream DNS resolver.
        #
        # @return [Async::DNS::Resolver]
        #
        # @api private
        attr_reader :resolver

        # The defined rules for the proxy server.
        #
        # @return [Array<Rule>]
        #
        # @api private
        attr_reader :rules

        #
        # Initializes the DNS server.
        #
        # @param [String] host
        #   The interface to listen on.
        #
        # @param [Integer] port
        #   The local port to listen on.
        #
        # @param [Array<String>] nameservers
        #   The upstream DNS server(s) to pass queries to.
        #
        # @param [Array<(Symbol, String, String), (Symbol, Regexp, String), (Symbol, Regexp, Proc)>] rules
        #   Optional rules to populate the server with.
        #
        # @yield [server]
        #   If a block is given, it will be passed the newly created server.
        #
        # @example Initializes a new DNS proxy server:
        #   server = Ronin::DNS::Proxy.new('127.0.0.1', 2346)
        #   server.add_rule :A, 'example.com', '10.0.0.1'
        #   server.add_rule :AAAA, 'example.com', 'dead:beef::1'
        #
        # @example Initializing a new DNS proxy server with a block:
        #   server = Ronin::DNS::Proxy.new('127.0.0.1', 2346) do |server|
        #     server.add_rule :A, 'example.com', '10.0.0.1'
        #     server.add_rule :AAAA, 'example.com', 'dead:beef::1'
        #   end
        #
        # @api public
        #
        def initialize(host,port, nameservers: Ronin::Support::Network::DNS.nameservers,
                                  rules: nil)
          @host = host
          @port = port

          super([[:udp, host, port]])

          @resolver = Async::DNS::Resolver.new(
            nameservers.map { |ip| [:udp, ip, 53] }
          )

          @rules = []

          if rules
            rules.each do |(record_type,name,result)|
              add_rule(record_type,name,result)
            end
          end

          yield self if block_given?
        end

        #
        # Adds a rule to the server.
        #
        # @param [:A, :AAAA, :ANY, :CNAME, :HINFO, :LOC, :MINFO, :MX, :NS, :PTR, :SOA, :SRV, :TXT, :WKS] record_type
        #   The record type that the rule will match against.
        #
        # @param [String, Regexp] name
        #   The record name that the rule will match against.
        #
        # @param [String, Array<String>, Symbol, Proc<Symbol, String, Async::DNS::Transaction>] result
        #   The result to respond with. It can be a String, or an Array of
        #   Strings, or an error code:
        #
        #   * `:NoError` - No error occurred.
        #   * `:FormErr` - The incoming data was not formatted correctly.
        #   * `:ServFail` - The operation caused a server failure (internal error, etc).
        #   * `:NXDomain` - Non-eXistant Domain (domain record does not exist).
        #   * `:NotImp` - The operation requested is not implemented.
        #   * `:Refused` - The operation was refused by the server.
        #   * `:NotAuth` - The server is not authoritive for the zone.
        #
        #   If a `Proc` is given, then it will be called with the query type,
        #   query name, and the DNS query transaction object.
        #
        # @example override the IP address for a domain:
        #   server.add_rule :A, 'example.com', '10.0.0.42'
        #
        # @example return multiple IP addresses:
        #   server.add_rule :A, 'example.com', ['10.0.0.42', '10.0.0.43']
        #
        # @example return an error for the given hostname:
        #   server.add_rule :A, 'updates.example.com', :ServFail
        #
        # @example match a query using a regex:
        #   server.add_rule :TXT, /^spf\./, "v=spf1 include:10.0.0.1 ~all"
        #
        # @example define a dynamic rule:
        #   server.add_rule :CNAME, /^www\./, ->(type,name,transaction) {
        #     # append '.hax' to the domain name
        #     names = name.split('.').push('hax')
        #
        #     transaction.respond!(names)
        #   }
        #
        # @api public
        #
        def add_rule(record_type,name,result)
          @rules << Rule.new(record_type,name,result)
        end

        # Mapping of Resolv resource classes to Symbols.
        #
        # @api private
        RECORD_TYPES = {
          Resolv::DNS::Resource::IN::A     => :A,
          Resolv::DNS::Resource::IN::AAAA  => :AAAA,
          Resolv::DNS::Resource::IN::ANY   => :ANY,
          Resolv::DNS::Resource::IN::CNAME => :CNAME,
          Resolv::DNS::Resource::IN::HINFO => :HINFO,
          Resolv::DNS::Resource::IN::LOC   => :LOC,
          Resolv::DNS::Resource::IN::MINFO => :MINFO,
          Resolv::DNS::Resource::IN::MX    => :MX,
          Resolv::DNS::Resource::IN::NS    => :NS,
          Resolv::DNS::Resource::IN::PTR   => :PTR,
          Resolv::DNS::Resource::IN::SOA   => :SOA,
          Resolv::DNS::Resource::IN::SRV   => :SRV,
          Resolv::DNS::Resource::IN::TXT   => :TXT,
          Resolv::DNS::Resource::IN::WKS   => :WKS
        }

        #
        # Processes a received query.
        #
        # @param [String] name
        #   The query value (ex: `www.example.com`).
        #
        # @param [Class<Resolv::DNS::Resource>] resource_class
        #   The resource class (ex: `Resolv::DNS::Resource::IN::A`).
        #
        # @param [Async::DNS::Transaction] transaction
        #   The DNS transaction object.
        #
        # @api private
        #
        def process(name,resource_class,transaction)
          query_type = RECORD_TYPES.fetch(resource_class)

          matched_rule = @rules.find do |rule|
            rule.matches?(query_type,name)
          end

          if matched_rule
            matched_rule.call(query_type,name,transaction)
          else
            transaction.passthrough!(@resolver)
          end
        end

      end
    end
  end
end
