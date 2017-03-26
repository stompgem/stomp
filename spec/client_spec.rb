# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'client_shared_examples'


describe Stomp::Client do
  let(:null_logger) { double("mock Stomp::NullLogger") }

  before(:each) do
    allow(Stomp::NullLogger).to receive(:new).and_return(null_logger)
    @mock_connection = double('connection', :autoflush= => true)
    allow(Stomp::Connection).to receive(:new).and_return(@mock_connection)
  end

  describe "(created with no params)" do

    before(:each) do
      @client = Stomp::Client.new
    end

    it "should not return any errors" do
      expect {
        @client = Stomp::Client.new
      }.not_to raise_error
    end

    it "should not return any errors when created with the open constructor" do
      expect {
        @client = Stomp::Client.open
      }.not_to raise_error
    end

    it_should_behave_like "standard Client"

  end

  describe 'delegated params' do
    before :each do
      @mock_connection = double('connection', :autoflush= => true,
                                              :login => 'dummy login',
                                              :passcode => 'dummy passcode',
                                              :port => 12345,
                                              :host => 'dummy host',
                                              :ssl => 'dummy ssl')
      allow(Stomp::Connection).to receive(:new).and_return(@mock_connection)
      @client = Stomp::Client.new
    end

    describe 'it should delegate parameters to its connection' do
      subject { @client }

      describe '#login' do
        subject { super().login }
        it { should eql 'dummy login' }
      end

      describe '#passcode' do
        subject { super().passcode }
        it { should eql 'dummy passcode' }
      end

      describe '#port' do
        subject { super().port }
        it { should eql 12345 }
      end

      describe '#host' do
        subject { super().host }
        it { should eql 'dummy host' }
      end

      describe '#ssl' do
        subject { super().ssl }
        it { should eql 'dummy ssl' }
      end
    end
  end

  describe "(autoflush)" do
    it "should delegate to the connection for accessing the autoflush property" do
      expect(@mock_connection).to receive(:autoflush)
      Stomp::Client.new.autoflush
    end

    it "should delegate to the connection for setting the autoflush property" do
      expect(@mock_connection).to receive(:autoflush=).with(true)
      Stomp::Client.new.autoflush = true
    end

    it "should set the autoflush property on the connection when passing in autoflush as a parameter to the Stomp::Client" do
      expect(@mock_connection).to receive(:autoflush=).with(true)
      Stomp::Client.new("login", "password", 'localhost', 61613, false, true)
    end
  end

  describe "(created with invalid params)" do

    it "should return ArgumentError if port is nil" do
      expect {
        @client = Stomp::Client.new('login', 'passcode', 'localhost', nil)
      }.to raise_error(ArgumentError)
    end

    it "should return ArgumentError if port is < 1" do
      expect {
        @client = Stomp::Client.new('login', 'passcode', 'localhost', 0)
      }.to raise_error(ArgumentError)
    end

    it "should return ArgumentError if port is > 65535" do
      expect {
        @client = Stomp::Client.new('login', 'passcode', 'localhost', 65536)
      }.to raise_error(ArgumentError)
    end

    it "should return ArgumentError if port is empty" do
      expect {
        @client = Stomp::Client.new('login', 'passcode', 'localhost', '')
      }.to raise_error(ArgumentError)
    end

    it "should return ArgumentError if reliable is something other than true or false" do
      expect {
        @client = Stomp::Client.new('login', 'passcode', 'localhost', '12345', 'foo')
      }.to raise_error(ArgumentError)
    end

  end


  describe "(created with positional params)" do
    before(:each) do
      @client = Stomp::Client.new('testlogin', 'testpassword', 'localhost', '12345', false)
	  @cli_thread = @client.parameters[:client_main]
    end

    it "should properly parse the URL provided" do
      expect(Stomp::Connection).to receive(:new).with(:hosts => [{:login => 'testlogin',
                                                              :passcode => 'testpassword',
                                                              :host => 'localhost',
                                                              :port => 12345}],
                                                  :logger => null_logger,
                                                  :reliable => false,
												:client_main => @cli_thread)
      Stomp::Client.new('testlogin', 'testpassword', 'localhost', '12345', false)
    end

    it_should_behave_like "standard Client"

  end

  describe "(created with non-authenticating stomp:// URL and non-TLD host)" do
    before(:each) do
      @client = Stomp::Client.new('stomp://foobar:12345')
	  @cli_thread = @client.parameters[:client_main]
    end

    it "should properly parse the URL provided" do
      expect(Stomp::Connection).to receive(:new).with(:hosts => [{:login => '',
                                                              :passcode => '',
                                                              :host => 'foobar',
                                                              :port => 12345}],
                                                  :logger => null_logger,
                                                  :reliable => false,
												:client_main => @cli_thread)
      Stomp::Client.new('stomp://foobar:12345')
    end

    it_should_behave_like "standard Client"

  end

  describe "(created with non-authenticating stomp:// URL and a host with a '-')" do

    before(:each) do
      @client = Stomp::Client.new('stomp://foo-bar:12345')
	  @cli_thread = @client.parameters[:client_main]
    end

    it "should properly parse the URL provided" do
      expect(Stomp::Connection).to receive(:new).with(:hosts => [{:login => '',
                                                              :passcode => '',
                                                              :host => 'foo-bar',
                                                              :port => 12345}],
                                                  :logger => null_logger,
                                                  :reliable => false,
												:client_main => @cli_thread)
      Stomp::Client.new('stomp://foo-bar:12345')
    end

    it_should_behave_like "standard Client"

  end
  
  describe "(created with authenticating stomp:// URL and non-TLD host)" do

    before(:each) do
      @client = Stomp::Client.new('stomp://test-login:testpasscode@foobar:12345')
	  @cli_thread = @client.parameters[:client_main]
    end

    it "should properly parse the URL provided" do
      expect(Stomp::Connection).to receive(:new).with(:hosts => [{:login => 'test-login',
                                                              :passcode => 'testpasscode',
                                                              :host => 'foobar',
                                                              :port => 12345}],
                                                  :logger => null_logger,
                                                  :reliable => false,
												:client_main => @cli_thread)
      Stomp::Client.new('stomp://test-login:testpasscode@foobar:12345')
    end

    it_should_behave_like "standard Client"

  end

  describe "(created with authenticating stomp:// URL and a host with a '-')" do

    before(:each) do
      @client = Stomp::Client.new('stomp://test-login:testpasscode@foo-bar:12345')
	  @cli_thread = @client.parameters[:client_main]
    end

    it "should properly parse the URL provided" do
      expect(Stomp::Connection).to receive(:new).with(:hosts => [{:login => 'test-login',
                                                              :passcode => 'testpasscode',
                                                              :host => 'foo-bar',
                                                              :port => 12345}],
                                                  :logger => null_logger,
                                                  :reliable => false,
												:client_main => @cli_thread)
      Stomp::Client.new('stomp://test-login:testpasscode@foo-bar:12345')
    end

    it_should_behave_like "standard Client"

  end

  describe "(created with non-authenticating stomp:// URL and TLD host)" do

    before(:each) do
      @client = Stomp::Client.new('stomp://host.foobar.com:12345')
	  @cli_thread = @client.parameters[:client_main]
    end

    after(:each) do
    end

    it "should properly parse the URL provided" do
      expect(Stomp::Connection).to receive(:new).with(:hosts => [{:login => '',
                                                              :passcode => '',
                                                              :host => 'host.foobar.com',
                                                              :port => 12345}],
                                                  :logger => null_logger,
                                                  :reliable => false,
												:client_main => @cli_thread)
      Stomp::Client.new('stomp://host.foobar.com:12345')
    end

    it_should_behave_like "standard Client"

  end

  describe "(created with authenticating stomp:// URL and non-TLD host)" do

    before(:each) do
      @client = Stomp::Client.new('stomp://testlogin:testpasscode@host.foobar.com:12345')
	  @cli_thread = @client.parameters[:client_main]
    end

    it "should properly parse the URL provided" do
      expect(Stomp::Connection).to receive(:new).with(:hosts => [{:login => 'testlogin',
                                                              :passcode => 'testpasscode',
                                                              :host => 'host.foobar.com',
                                                              :port => 12345}],
                                                  :logger => null_logger,
                                                  :reliable => false,
												:client_main => @cli_thread)
      Stomp::Client.new('stomp://testlogin:testpasscode@host.foobar.com:12345')
    end

    it_should_behave_like "standard Client"

  end
  
  describe "(created with failover URL)" do
    before(:each) do
	  @client = Stomp::Client.new('failover://(stomp://login1:passcode1@localhost:61616,stomp://login2:passcode2@remotehost:61617)')
	  @cli_thread = @client.parameters[:client_main]
      #default options
      @parameters = {
        :initial_reconnect_delay => 0.01,
        :max_reconnect_delay => 30.0,
        :use_exponential_back_off => true,
        :back_off_multiplier => 2,
        :max_reconnect_attempts => 0,
        :randomize => false,
        :connect_timeout => 0,
        :reliable => true
      }
    end
    it "should properly parse a URL with failover://" do
      url = "failover://(stomp://login1:passcode1@localhost:61616,stomp://login2:passcode2@remotehost:61617)"
      @parameters[:hosts] = [
        {:login => "login1", :passcode => "passcode1", :host => "localhost", :port => 61616, :ssl => false},
        {:login => "login2", :passcode => "passcode2", :host => "remotehost", :port => 61617, :ssl => false}
      ]
      @parameters.merge!({:logger => null_logger})
      expect(Stomp::Connection).to receive(:new).with(@parameters)
	  @parameters[:client_main] = @cli_thread
	  client = Stomp::Client.new(url)
      expect(client.parameters).to eq(@parameters)
    end
    
    it "should properly parse a URL with failover:" do
      url = "failover:(stomp://login1:passcode1@localhost:61616,stomp://login2:passcode2@remotehost1:61617,stomp://login3:passcode3@remotehost2:61618)"
      
      @parameters[:hosts] = [
        {:login => "login1", :passcode => "passcode1", :host => "localhost", :port => 61616, :ssl => false},
        {:login => "login2", :passcode => "passcode2", :host => "remotehost1", :port => 61617, :ssl => false},
        {:login => "login3", :passcode => "passcode3", :host => "remotehost2", :port => 61618, :ssl => false}
      ]
      
      @parameters.merge!({:logger => null_logger})
	  @parameters[:client_main] = @cli_thread
      expect(Stomp::Connection).to receive(:new).with(@parameters)
      client = Stomp::Client.new(url)
      expect(client.parameters).to eq(@parameters)
    end
    
    it "should properly parse a URL without user and password" do
      url = "failover:(stomp://localhost:61616,stomp://remotehost:61617)"

      @parameters[:hosts] = [
        {:login => "", :passcode => "", :host => "localhost", :port => 61616, :ssl => false},
        {:login => "", :passcode => "", :host => "remotehost", :port => 61617, :ssl => false}
      ]
      
      @parameters.merge!({:logger => null_logger})
      @parameters[:client_main] = @cli_thread
      expect(Stomp::Connection).to receive(:new).with(@parameters)
      
      client = Stomp::Client.new(url)
	  @parameters[:client_main] = client.parameters[:client_main]
      expect(client.parameters).to eq(@parameters)
    end
    
    it "should properly parse a URL with user and/or password blank" do
      url = "failover:(stomp://@localhost:61616,stomp://@remotehost:61617)"
      
      @parameters[:hosts] = [
        {:login => "", :passcode => "", :host => "localhost", :port => 61616, :ssl => false},
        {:login => "", :passcode => "", :host => "remotehost", :port => 61617, :ssl => false}
      ]
      
      @parameters.merge!({:logger => null_logger})
      @parameters[:client_main] = @cli_thread
      expect(Stomp::Connection).to receive(:new).with(@parameters)
      
      client = Stomp::Client.new(url)
	  @parameters[:client_main] = client.parameters[:client_main]
      expect(client.parameters).to eq(@parameters)
    end
    
    it "should properly parse a URL with the options query" do
      query = "initialReconnectDelay=5000&maxReconnectDelay=60000&useExponentialBackOff=false&backOffMultiplier=3"
      query += "&maxReconnectAttempts=4&randomize=true&backup=true&timeout=10000"
      
      url = "failover:(stomp://login1:passcode1@localhost:61616,stomp://login2:passcode2@remotehost:61617)?#{query}"
      
      #
      @parameters = {
        :initial_reconnect_delay => 5.0,
        :max_reconnect_delay => 60.0,
        :use_exponential_back_off => false,
        :back_off_multiplier => 3,
        :max_reconnect_attempts => 4,
        :randomize => true,
        :connect_timeout => 0,
        :reliable => true
      }
      
      @parameters[:hosts] = [
        {:login => "login1", :passcode => "passcode1", :host => "localhost", :port => 61616, :ssl => false},
        {:login => "login2", :passcode => "passcode2", :host => "remotehost", :port => 61617, :ssl => false}
      ]
      
      @parameters.merge!({:logger => null_logger})
      @parameters[:client_main] = @cli_thread
      expect(Stomp::Connection).to receive(:new).with(@parameters)
      
      client = Stomp::Client.new(url)
	  @parameters[:client_main] = client.parameters[:client_main]
      expect(client.parameters).to eq(@parameters)
    end
    
  end


  describe '#error_listener' do
    context 'on getting a ResourceAllocationException' do
      let(:message) do
        message = Stomp::Message.new('')
        message.body = "javax.jms.ResourceAllocationException: Usage"
        message.headers = {'message' => %q{message = "Usage Manager Memory Limit reached. Stopping producer (ID:producer) to prevent flooding queue://errors. See } }
        message.command = Stomp::CMD_ERROR
        message
      end
  
      it 'should handle ProducerFlowControlException errors by raising' do
        expect do
          @client = Stomp::Client.new
          @error_listener = @client.instance_variable_get(:@error_listener)
          @error_listener.call(message)
        end.to raise_exception(Stomp::Error::ProducerFlowControlException)
      end
    end
  end

  describe '(used with custom headers)' do
    before :each do
      @client = Stomp::Client.new
    end

    def original_headers
      {:custom_header => 'value'}
    end

    let(:connection_headers) { original_headers }
    let(:headers) { original_headers }

    shared_examples_for 'argument-safe method' do
      describe 'given headers hash' do
        subject { headers }
        it 'is immutable' do
          expect match(original_headers)
        end
      end
    end

    describe '#begin' do
      before {
        expect(@mock_connection).to receive(:begin).with('name', connection_headers)
        @client.begin('name', headers)
      }
      it_behaves_like 'argument-safe method'
    end

    describe '#abort' do
      before {
        expect(@mock_connection).to receive(:abort).with('name', connection_headers)
        @client.abort('name', headers)
      }
      it_behaves_like 'argument-safe method'
    end

    describe '#commit' do
      before {
        expect(@mock_connection).to receive(:commit).with('name', connection_headers)
        @client.commit('name', headers)
      }
      it_behaves_like 'argument-safe method'
    end

    describe '#subscribe' do
      let(:connection_headers) { original_headers.merge({:id => Digest::SHA1.hexdigest('destination')}) }
      before {
        expect(@mock_connection).to receive(:subscribe).with('destination', connection_headers)
        @client.subscribe('destination', headers) {|dummy_subscriber| }
      }
      it_behaves_like 'argument-safe method'
    end

    describe '#unsubscribe' do
      let(:connection_headers) { original_headers.merge({:id => Digest::SHA1.hexdigest('destination')}) }
      before {
        expect(@mock_connection).to receive(:unsubscribe).with('destination', connection_headers)
        @client.unsubscribe('destination', headers) {|dummy_subscriber| }
      }
      it_behaves_like 'argument-safe method'
    end

    describe '#ack' do
      describe 'with STOMP 1.0' do
        let(:message) { double('message', :headers => {'message-id' => 'id'}) }
        before {
          allow(@client).to receive(:protocol).and_return(Stomp::SPL_10)
          expect(@mock_connection).to receive(:ack).with('id', connection_headers)
          @client.ack(message, headers)
        }
        it_behaves_like 'argument-safe method'
      end
      describe 'with STOMP 1.1' do
        let(:message) { double('message', :headers => {'message-id' => 'id', 'subscription' => 'subscription_name'}) }
        let(:connection_headers) { original_headers.merge({:subscription => 'subscription_name'}) }
        before {
          allow(@client).to receive(:protocol).and_return(Stomp::SPL_11)
          expect(@mock_connection).to receive(:ack).with('id', connection_headers)
          @client.ack(message, headers)
        }
        it_behaves_like 'argument-safe method'
      end
      describe 'with STOMP 1.2' do
        let(:message) { double('message', :headers => {'ack' => 'id'}) }
        before {
          allow(@client).to receive(:protocol).and_return(Stomp::SPL_12)
          expect(@mock_connection).to receive(:ack).with('id', connection_headers)
          @client.ack(message, headers)
        }
        it_behaves_like 'argument-safe method'
      end
    end

    describe '#nack' do
      describe 'with STOMP 1.0' do
        let(:message) { double('message', :headers => {'message-id' => 'id'}) }
        before {
          allow(@client).to receive(:protocol).and_return(Stomp::SPL_10)
          expect(@mock_connection).to receive(:nack).with('id', connection_headers)
          @client.nack(message, headers)
        }
        it_behaves_like 'argument-safe method'
      end
      describe 'with STOMP 1.1' do
        let(:message) { double('message', :headers => {'message-id' => 'id', 'subscription' => 'subscription_name'}) }
        let(:connection_headers) { original_headers.merge({:subscription => 'subscription_name'}) }
        before {
          allow(@client).to receive(:protocol).and_return(Stomp::SPL_11)
          expect(@mock_connection).to receive(:nack).with('id', connection_headers)
          @client.nack(message, headers)
        }
        it_behaves_like 'argument-safe method'
      end
      describe 'with STOMP 1.2' do
        let(:message) { double('message', :headers => {'ack' => 'id'}) }
        before {
          allow(@client).to receive(:protocol).and_return(Stomp::SPL_12)
          expect(@mock_connection).to receive(:nack).with('id', connection_headers)
          @client.nack(message, headers)
        }
        it_behaves_like 'argument-safe method'
      end
    end

    describe '#publish' do
      describe 'without listener' do
        let(:message) { double('message') }
        before {
          expect(@mock_connection).to receive(:publish).with('destination', message, connection_headers)
          @client.publish('destination', message, headers)
        }
        it_behaves_like 'argument-safe method'
      end
      describe 'with listener' do
        let(:message) { double('message') }
        let(:connection_headers) { original_headers.merge({:receipt => 'receipt-uuid'}) }
        before {
          allow(@client).to receive(:uuid).and_return('receipt-uuid')
          expect(@mock_connection).to receive(:publish).with('destination', message, connection_headers)
          @client.publish('destination', message, headers) {|dummy_listener| }
        }
        it_behaves_like 'argument-safe method'
      end
    end

  end
end
