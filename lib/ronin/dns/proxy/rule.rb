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

module Ronin
  module DNS
    module Proxy
      #
      # Represents a DNS rule for the DNS {Server}.
      #
      # @api private
      #
      class Rule

        # The record type to match.
        #
        # @return [:A, :AAAA, :ANY, :CNAME, :HINFO, :LOC, :MINFO, :MX, :NS, :PTR, :SOA, :SRV, :TXT, :WKS]
        attr_reader :type

        # The record name or regex to match.
        #
        # @return [String, Regexp]
        attr_reader :name

        # The result to return.
        #
        # @return [String, Array<String>, Symbol, #call]
        attr_reader :result

        #
        # Initializes the DNS rule.
        #
        # @param [:A, :AAAA, :ANY, :CNAME, :HINFO, :LOC, :MINFO, :MX, :NS, :PTR, :SOA, :SRV, :TXT, :WKS] type
        #   The rule's record type.
        #
        # @param [String, Regexp] name
        #   The rule's name to match.
        #
        # @param [String, Array<String>, Symbol, #call] result
        #   The result to return.
        #
        # @yield [type, name, transaction]
        #   If no result argument is given, the given block will be passed the
        #   DNS query's type, name, and transaction object.
        #
        # @yieldparam [Symbol] type
        #   The query type.
        #
        # @yieldparam [String] name
        #   The queried host name.
        #
        # @yieldparam [Async::DNS::Transaction] transaction
        #   The DNS query transaction object.
        #
        # @raise [ArgumentError]
        #   Must specify a `result` argument or a block.
        #
        def initialize(type,name,result=nil,&block)
          unless (result || block)
            raise(ArgumentError,"must specify a result value or a block")
          end

          @type   = type
          @name   = name
          @result = result || block
        end

        #
        # Determines if the rule matches the query type and query name.
        #
        # @param [:A, :AAAA, :ANY, :CNAME, :HINFO, :LOC, :MINFO, :MX, :NS, :PTR, :SOA, :SRV, :TXT, :WKS] query_type
        #   The query's type (ex: `:A`).
        #
        # @param [String] query_name
        #   The query's name (ex: 'www.example.com').
        #
        # @return [Boolean]
        #   Indicates whether the rule matches the query.
        #
        def matches?(query_type,query_name)
          (@type == query_type) && (@name === query_name)
        end

        #
        # Invokes the rule with the given query type, query name, and DNS
        # transaction object.
        #
        # @param [:A, :AAAA, :ANY, :CNAME, :HINFO, :LOC, :MINFO, :MX, :NS, :PTR, :SOA, :SRV, :TXT, :WKS] query_type
        #   The query's type (ex: `:A`).
        #
        # @param [String] query_name
        #   The query's name (ex: 'www.example.com').
        #
        # @return [Async::DNS::Transaction] transaction
        #   The DNS query transaction.
        #
        def call(query_type,query_name,transaction)
          if @result.respond_to?(:call)
            @result.call(query_type,query_name,transaction)
          elsif @result.kind_of?(Symbol)
            transaction.fail!(@result)
          elsif @result
            transaction.respond!(@result)
          end
        end

      end
    end
  end
end
