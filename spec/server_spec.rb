require 'spec_helper'
require 'ronin/dns/proxy/server'

describe Ronin::DNS::Proxy::Server do
  let(:host) { '127.0.0.1' }
  let(:port) { 53 }

  subject { described_class.new(host,port) }

  describe "#initialize" do
    it "must set #host" do
      expect(subject.host).to eq(host)
    end

    it "must set #port" do
      expect(subject.port).to eq(port)
    end

    it "must initialize #rules to an empty Array" do
      expect(subject.rules).to eq([])
    end

    it "must initialize #resolver to Async::DNS::Resolver" do
      expect(subject.resolver).to be_kind_of(Async::DNS::Resolver)
    end

    context "when the rules: keyword is given" do
      let(:rules) do
        [
          [:A, 'example.com', '127.0.0.1'],
          [:A, /\.example\.com$/, '10.0.0.1']
        ]
      end

      subject do
        described_class.new(host,port, rules: rules)
      end

      it "must populate #rules with Ronin::DNS::Proxy::Rule objects" do
        expect(subject.rules.length).to eq(rules.length)
        expect(subject.rules[0]).to be_kind_of(Ronin::DNS::Proxy::Rule)
        expect(subject.rules[0].type).to eq(rules[0][0])
        expect(subject.rules[0].name).to eq(rules[0][1])
        expect(subject.rules[0].result).to eq(rules[0][2])
        expect(subject.rules[1]).to be_kind_of(Ronin::DNS::Proxy::Rule)
        expect(subject.rules[1].type).to eq(rules[1][0])
        expect(subject.rules[1].name).to eq(rules[1][1])
        expect(subject.rules[1].result).to eq(rules[1][2])
      end
    end

    context "when a block is given" do
      it "must yield the new Ronin::DNS::Proxy::Server object" do
        expect { |b|
          described_class.new(host,port,&b)
        }.to yield_successive_args(described_class)
      end
    end
  end

  describe "#rule" do
    let(:record_type)   { :A }
    let(:record_name)   { 'example.com' }
    let(:record_result) { '10.0.0.1' }

    context "when type, name, and result arguments are given" do
      before do
        subject.rule :TXT, 'foo.example.com', '1.2.3.4'
        subject.rule record_type, record_name, record_result
      end

      it "must append a new Ronin::DNS::Proxy::Rule object to #rules with the type, name, and result arguments" do
        expect(subject.rules.last).to be_kind_of(Ronin::DNS::Proxy::Rule)
        expect(subject.rules.last.type).to eq(record_type)
        expect(subject.rules.last.name).to eq(record_name)
        expect(subject.rules.last.result).to eq(record_result)
      end
    end

    context "when no result argument is given" do
      context "but a block is given" do
        let(:block) do
          proc { |type,name,transaction|
            transaction.respond!('foo')
          }
        end

        before do
          subject.rule :TXT, 'foo.example.com', '1.2.3.4'
          subject.rule(record_type,record_name,&block)
        end

        it "must set the rule's result to the given block" do
          expect(subject.rules.last).to be_kind_of(Ronin::DNS::Proxy::Rule)
          expect(subject.rules.last.type).to eq(record_type)
          expect(subject.rules.last.name).to eq(record_name)
          expect(subject.rules.last.result).to be(block)
        end
      end

      context "and no block is given" do
        it do
          expect {
            subject.rule(record_type,record_name)
          }.to raise_error(ArgumentError,"must specify a result value or a block")
        end
      end
    end
  end

  describe "#process" do
    let(:query_name)   { 'foo.example.com' }
    let(:record_class) { Resolv::DNS::Resource::IN::A }
    let(:transaction)  { double('Async::DNS::Transaction') }

    context "when the query matches a rule" do
      let(:rule_type)   { :A }
      let(:rule_name)   { query_name }
      let(:rule_result) { '10.0.0.1' }

      before do
        subject.rule rule_type, rule_name, rule_result
      end

      it "must return the result from the rule" do
        expect(transaction).to receive(:respond!).with(rule_result)

        subject.process(query_name,record_class,transaction)
      end
    end

    context "when the query does not match any rule" do
      before do
        subject.rule :A, 'will.not.match.example.com', '1.2.3.4'
      end

      it "must pass through the query to the upstream resolver" do
        expect(transaction).to receive(:passthrough!).with(subject.resolver)

        subject.process(query_name,record_class,transaction)
      end
    end
  end
end
