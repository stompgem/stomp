# -*- encoding: utf-8 -*-

require 'spec_helper'

shared_examples_for "standard Client" do

  before(:each) do
    @destination = "/queue/test/ruby/client"
    @message_text = "test_client-#{Time.now.to_i}"
  end

  describe "the closed? method" do
    it "should be false when the connection is open" do
      allow(@mock_connection).to receive(:closed?).and_return(false)
      expect(@client.closed?).to eq(false)
    end

    it "should be true when the connection is closed" do
      allow(@mock_connection).to receive(:closed?).and_return(true)
      expect(@client.closed?).to eq(true)
    end
  end

  describe "the open? method" do
    it "should be true when the connection is open" do
      allow(@mock_connection).to receive(:open?).and_return(true)
      expect(@client.open?).to eq(true)
    end

    it "should be false when the connection is closed" do
      allow(@mock_connection).to receive(:open?).and_return(false)
      expect(@client.open?).to eq(false)
    end
  end

  describe "the subscribe method" do

    before(:each) do
      allow(@mock_connection).to receive(:subscribe).and_return(true)
    end

    it "should raise RuntimeError if not passed a block" do
      expect {
        @client.subscribe(@destination)
      }.to raise_error(RuntimeError)
    end

    it "should not raise an error when passed a block" do
      expect {
        @client.subscribe(@destination) {|msg| received = msg}
      }.not_to raise_error
    end

    it "should raise RuntimeError on duplicate subscriptions" do
      expect {
        @client.subscribe(@destination)
        @client.subscribe(@destination)
      }.to raise_error(RuntimeError)
    end

    it "should raise RuntimeError with duplicate id headers" do
      expect {
        @client.subscribe(@destination, {'id' => 'abcdef'})
        @client.subscribe(@destination, {'id' => 'abcdef'})
      }.to raise_error(RuntimeError)
    end

  end

end

