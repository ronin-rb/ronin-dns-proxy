require 'spec_helper'
require 'ronin/dns/proxy/rule'

describe Ronin::DNS::Proxy::Rule do
  let(:type)   { :A }
  let(:name)   { 'foo.example.com' }
  let(:result) { '127.0.0.1' }

  subject { described_class.new(type,name,result) }

  describe "#initialize" do
    it "must set #type" do
      expect(subject.type).to eq(type)
    end

    it "must set #name" do
      expect(subject.name).to eq(name)
    end

    it "must set #result" do
      expect(subject.result).to eq(result)
    end
  end

  describe "#matches?" do
    context "when #name is a String" do
      context "when the given type and name match #type and #name" do
        it "must return true" do
          expect(subject.matches?(type,name)).to be(true)
        end
      end

      context "when the given type does not match #type" do
        it "must return false" do
          expect(subject.matches?(:SRV,name)).to be(false)
        end
      end

      context "when the given name ends with #name" do
        it "must return false" do
          expect(subject.matches?(type,"subdomain.#{name}")).to be(false)
        end
      end

      context "when the given name does not match #name" do
        it "must return false" do
          expect(subject.matches?(type,"totally.different.com")).to be(false)
        end
      end
    end

    context "when #type is a Regexp" do
      let(:name) { /\.example.com$/ }

      context "when the given type and name matches #type and #name exactly" do
        let(:name) { /^example.com$/ }

        it "must return true" do
          expect(subject.matches?(type,"example.com")).to be(true)
        end
      end

      context "when the given type and name matches #type and #name partially" do
        it "must return true" do
          expect(subject.matches?(type,"subdomain.example.com")).to be(true)
        end
      end

      context "when the given type does not match #type" do
        it "must return false" do
          expect(subject.matches?(:SRV,name)).to be(false)
        end
      end

      context "when the given name does not match #name" do
        it "must return false" do
          expect(subject.matches?(type,"totally.different.com")).to be(false)
        end
      end
    end
  end

  describe "#call" do
    let(:query_type)  { type }
    let(:query_name)  { name }
    let(:transaction) { double('Async::DNS::Transaction') }

    context "when #result is callable" do
      let(:result) { double('Proc') }

      it "must call the #result with the given query type, query name, and transaction object" do
        expect(result).to receive(:call).with(query_type,query_name,transaction)

        subject.call(query_type,query_name,transaction)
      end
    end

    context "when #result is a Symbol" do
      let(:result) { :ServFail }

      it "must fail the transaction using the result Symbol as an error code" do
        expect(transaction).to receive(:fail!).with(result)

        subject.call(query_type,query_name,transaction)
      end
    end

    context "when #result is String" do
      it "must respond to the transaction using the #result value" do
        expect(transaction).to receive(:respond!).with(result)

        subject.call(query_type,query_name,transaction)
      end
    end

    context "when #result is an Array of Strings" do
      let(:query_type) { :NS }
      let(:result)     { %w[127.0.0.1 127.0.0.2] }

      it "must respond to the transaction using the #result value" do
        expect(transaction).to receive(:respond!).with(result)

        subject.call(query_type,query_name,transaction)
      end
    end
  end
end
