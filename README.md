# ronin-dns-proxy

[![CI](https://github.com/ronin-rb/ronin-dns-proxy/actions/workflows/ruby.yml/badge.svg)](https://github.com/ronin-rb/ronin-dns-proxy/actions/workflows/ruby.yml)
[![Code Climate](https://codeclimate.com/github/ronin-rb/ronin-dns-proxy.svg)](https://codeclimate.com/github/ronin-rb/ronin-dns-proxy)

* [Website](https://ronin-rb.dev/)
* [Source](https://github.com/ronin-rb/ronin-dns-proxy)
* [Issues](https://github.com/ronin-rb/ronin-dns-proxy/issues)
* [Documentation](https://ronin-rb.dev/docs/ronin-dns-proxy)
* [Discord](https://discord.gg/6WAb3PsVX9) |
  [Twitter](https://twitter.com/ronin_rb) |
  [Mastodon](https://infosec.exchange/@ronin_rb)

## Description

ronin-dns-proxy is a configurable DNS proxy server library. It supports
reutrning spoofing DNS results or passing DNS queries through to the upstream
DNS nameserver.

## Features

* Supports returning spoofed results to specific DNS queries.
* Supports matching queries with regular expressions.
* Supports dynamic DNS server rules.
* Passing through all other DNS queries.

## Examples

```ruby
require 'ronin/dns/proxy'

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
```

Then try running `host -p 2346 example.com 127.0.0.1` once the server is
running.

## Requirements

* [Ruby] >= 3.0.0
* [async-dns] ~> 1.0
* [ronin-support] ~> 1.0

## Install

```shell
$ gem install ronin-dns-proxy
```

### Gemfile

```ruby
gem 'ronin-dns-proxy', '~> 0.1'
```

### gemspec

```ruby
gem.add_dependency 'ronin-dns-proxy', '~> 0.1'
```

## Development

1. [Fork It!](https://github.com/ronin-rb/ronin-dns-proxy/fork)
2. Clone It!
3. `cd ronin-dns-proxy/`
4. `bundle install`
5. `git checkout -b my_feature`
6. Code It!
7. `bundle exec rake spec`
8. `git push origin my_feature`

## License

Copyright (c) 2023 Hal Brodigan (postmodern.mod3@gmail.com)

ronin-dns-proxy is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ronin-dns-proxy is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with ronin-dns-proxy.  If not, see <https://www.gnu.org/licenses/>.

[Ruby]: https://www.ruby-lang.org
[async-dns]: https://github.com/socketry/async-dns#readme
[ronin-support]: https://github.com/ronin-rb/ronin-support#readme
