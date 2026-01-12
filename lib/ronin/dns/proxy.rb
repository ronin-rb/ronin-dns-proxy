# frozen_string_literal: true
#
# ronin-dns-proxy - A DNS server and proxy library.
#
# Copyright (c) 2023-2026 Hal Brodigan (postmodern.mod3@gmail.com)
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

require_relative 'proxy/server'

module Ronin
  module DNS
    #
    # Namespace for `ronin-dns-proxy`.
    #
    module Proxy
      #
      # Starts a new DNS proxy listening on the given host and port.
      #
      # @param [String] host
      #   The interface to listen on.
      #
      # @param [Integer] port
      #   The local port to listen on.
      #
      # @param [Hash{Symbol => Object}] kwargs
      #   Additional keyword arguments for {Server#initialize}.
      #
      # @option kwargs [Array<String>] :nameservers (Ronin::Support::Network::DNS.nameservers)
      #   The upstream DNS server(s) to pass queries to.
      #
      # @option kwargs [Array<(Symbol, String, String), (Symbol, Regexp, String), (Symbol, Regexp, Proc)>] rules
      #   Optional rules to populate the server with.
      #
      # @yield [server]
      #   If a block is given, it will be passed the newly created DNS proxy
      #   server object.
      #
      # @yieldparam [Server] server
      #   The newly created DNS proxy server.
      #
      # @example
      #   require 'ronin/dns/proxy'
      #
      #   Ronin::DNS::Proxy.run('127.0.0.1', 2346) do |server|
      #     server.rule :A, 'example.com', '10.0.0.1'
      #     server.rule :AAAA, 'example.com', 'dead:beef::1'
      #   end
      #
      def self.run(host,port,**kwargs,&block)
        server = Server.new(host,port,**kwargs,&block)
        server.run
      end
    end
  end
end
