# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'client_shared_examples'


describe Stomp::Client do
  let(:null_logger) { double("mock Stomp::NullLogger") }

  before(:each) do
    Stomp::NullLogger.stub(:new).and_return(null_logger)
    @mock_connection = double('connection', :autoflush= => true)
    Stomp::Connection.stub(:new).and_return(@mock_connection)
  end

  describe "(created with no params)" do

    before(:each) do
      @client = Stomp::Client.new
    end

    it "should not return any errors" do
      lambda {
        @client = Stomp::Client.new
      }.should_not raise_error
    end

    it "should not return any errors when created with the open constructor" do
      lambda {
        @client = Stomp::Client.open
      }.should_not raise_error
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
      Stomp::Connection.stub(:new).and_return(@mock_connection)
      @client = Stomp::Client.new
    end

    describe 'it should delegate parameters to its connection' do
      subject { @client }

      its(:login) { should eql 'dummy login' }
      its(:passcode) { should eql 'dummy passcode' }
      its(:port) { should eql 12345 }
      its(:host) { should eql 'dummy host' }
      its(:ssl) { should eql 'dummy ssl' }
    end
  end

  describe "(autoflush)" do
    it "should delegate to the connection for accessing the autoflush property" do
      @mock_connection.should_receive(:autoflush)
      Stomp::Client.new.autoflush
    end

    it "should delegate to the connection for setting the autoflush property" do
      @mock_connection.should_receive(:autoflush=).with(true)
      Stomp::Client.new.autoflush = true
    end

    it "should set the autoflush property on the connection when passing in autoflush as a parameter to the Stomp::Client" do
      @mock_connection.should_receive(:autoflush=).with(true)
      Stomp::Client.new("login", "password", 'localhost', 61613, false, true)
    end
  end

  describe "(created with invalid params)" do

    it "should return ArgumentError if host is nil" do
      lambda {
        @client = Stomp::Client.new('login', 'passcode', nil)
      }.should raise_error
    end

    it "should return ArgumentError if host is empty" do
      lambda {
        @client = Stomp::Client.new('login', 'passcode', '')
      }.should raise_error
    end

    it "should return ArgumentError if port is nil" do
      lambda {
        @client = Stomp::Client.new('login', 'passcode', 'localhost', nil)
      }.should raise_error
    end

    it "should return ArgumentError if port is < 1" do
      lambda {
        @client = Stomp::Client.new('login', 'passcode', 'localhost', 0)
      }.should raise_error
    end

    it "should return ArgumentError if port is > 65535" do
      lambda {
        @client = Stomp::Client.new('login', 'passcode', 'localhost', 65536)
      }.should raise_error
    end

    it "should return ArgumentError if port is empty" do
      lambda {
        @client = Stomp::Client.new('login', 'passcode', 'localhost', '')
      }.should raise_error
    end

    it "should return ArgumentError if reliable is something other than true or false" do
      lambda {
        @client = Stomp::Client.new('login', 'passcode', 'localhost', '12345', 'foo')
      }.should raise_error
    end

  end


  describe "(created with positional params)" do
    before(:each) do
      @client = Stomp::Client.new('testlogin', 'testpassword', 'localhost', '12345', false)
    end

    it "should properly parse the URL provided" do
      Stomp::Connection.should_receive(:new).with(:hosts => [{:login => 'testlogin',
                                                              :passcode => 'testpassword',
                                                              :host => 'localhost',
                                                              :port => 12345}],
                                                  :logger => null_logger,
                                                  :reliable => false)
      Stomp::Client.new('testlogin', 'testpassword', 'localhost', '12345', false)
    end

    it_should_behave_like "standard Client"

  end

  describe "(created with non-authenticating stomp:// URL and non-TLD host)" do
    before(:each) do
      @client = Stomp::Client.new('stomp://foobar:12345')
    end

    it "should properly parse the URL provided" do
      Stomp::Connection.should_receive(:new).with(:hosts => [{:login => '',
                                                              :passcode => '',
                                                              :host => 'foobar',
                                                              :port => 12345}],
                                                  :logger => null_logger,
                                                  :reliable => false)
      Stomp::Client.new('stomp://foobar:12345')
    end

    it_should_behave_like "standard Client"

  end

  describe "(created with non-authenticating stomp:// URL and a host with a '-')" do

    before(:each) do
      @client = Stomp::Client.new('stomp://foo-bar:12345')
    end

    it "should properly parse the URL provided" do
      Stomp::Connection.should_receive(:new).with(:hosts => [{:login => '',
                                                              :passcode => '',
                                                              :host => 'foo-bar',
                                                              :port => 12345}],
                                                  :logger => null_logger,
                                                  :reliable => false)
      Stomp::Client.new('stomp://foo-bar:12345')
    end

    it_should_behave_like "standard Client"

  end
  
  describe "(created with authenticating stomp:// URL and non-TLD host)" do

    before(:each) do
      @client = Stomp::Client.new('stomp://test-login:testpasscode@foobar:12345')
    end

    it "should properly parse the URL provided" do
      Stomp::Connection.should_receive(:new).with(:hosts => [{:login => 'test-login',
                                                              :passcode => 'testpasscode',
                                                              :host => 'foobar',
                                                              :port => 12345}],
                                                  :logger => null_logger,
                                                  :reliable => false)
      Stomp::Client.new('stomp://test-login:testpasscode@foobar:12345')
    end

    it_should_behave_like "standard Client"

  end

  describe "(created with authenticating stomp:// URL and a host with a '-')" do

    before(:each) do
      @client = Stomp::Client.new('stomp://test-login:testpasscode@foo-bar:12345')
    end

    it "should properly parse the URL provided" do
      Stomp::Connection.should_receive(:new).with(:hosts => [{:login => 'test-login',
                                                              :passcode => 'testpasscode',
                                                              :host => 'foo-bar',
                                                              :port => 12345}],
                                                  :logger => null_logger,
                                                  :reliable => false)
      Stomp::Client.new('stomp://test-login:testpasscode@foo-bar:12345')
    end

    it_should_behave_like "standard Client"

  end

  describe "(created with non-authenticating stomp:// URL and TLD host)" do

    before(:each) do
      @client = Stomp::Client.new('stomp://host.foobar.com:12345')
    end

    after(:each) do
    end

    it "should properly parse the URL provided" do
      Stomp::Connection.should_receive(:new).with(:hosts => [{:login => '',
                                                              :passcode => '',
                                                              :host => 'host.foobar.com',
                                                              :port => 12345}],
                                                  :logger => null_logger,
                                                  :reliable => false)
      Stomp::Client.new('stomp://host.foobar.com:12345')
    end

    it_should_behave_like "standard Client"

  end

  describe "(created with authenticating stomp:// URL and non-TLD host)" do

    before(:each) do
      @client = Stomp::Client.new('stomp://testlogin:testpasscode@host.foobar.com:12345')
    end

    it "should properly parse the URL provided" do
      Stomp::Connection.should_receive(:new).with(:hosts => [{:login => 'testlogin',
                                                              :passcode => 'testpasscode',
                                                              :host => 'host.foobar.com',
                                                              :port => 12345}],
                                                  :logger => null_logger,
                                                  :reliable => false)
      Stomp::Client.new('stomp://testlogin:testpasscode@host.foobar.com:12345')
    end

    it_should_behave_like "standard Client"

  end
  
  describe "(created with failover URL)" do
    before(:each) do
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
      
      Stomp::Connection.should_receive(:new).with(@parameters)
      
      client = Stomp::Client.new(url)
      client.parameters.should == @parameters
    end
    
    it "should properly parse a URL with failover:" do
      url = "failover:(stomp://login1:passcode1@localhost:61616,stomp://login2:passcode2@remotehost1:61617,stomp://login3:passcode3@remotehost2:61618)"
      
      @parameters[:hosts] = [
        {:login => "login1", :passcode => "passcode1", :host => "localhost", :port => 61616, :ssl => false},
        {:login => "login2", :passcode => "passcode2", :host => "remotehost1", :port => 61617, :ssl => false},
        {:login => "login3", :passcode => "passcode3", :host => "remotehost2", :port => 61618, :ssl => false}
      ]
      
      @parameters.merge!({:logger => null_logger})
      
      Stomp::Connection.should_receive(:new).with(@parameters)
      
      client = Stomp::Client.new(url)
      client.parameters.should == @parameters
    end
    
    it "should properly parse a URL without user and password" do
      url = "failover:(stomp://localhost:61616,stomp://remotehost:61617)"

      @parameters[:hosts] = [
        {:login => "", :passcode => "", :host => "localhost", :port => 61616, :ssl => false},
        {:login => "", :passcode => "", :host => "remotehost", :port => 61617, :ssl => false}
      ]
      
      @parameters.merge!({:logger => null_logger})
      
      Stomp::Connection.should_receive(:new).with(@parameters)
      
      client = Stomp::Client.new(url)
      client.parameters.should == @parameters
    end
    
    it "should properly parse a URL with user and/or password blank" do
      url = "failover:(stomp://@localhost:61616,stomp://@remotehost:61617)"
      
      @parameters[:hosts] = [
        {:login => "", :passcode => "", :host => "localhost", :port => 61616, :ssl => false},
        {:login => "", :passcode => "", :host => "remotehost", :port => 61617, :ssl => false}
      ]
      
      @parameters.merge!({:logger => null_logger})
      
      Stomp::Connection.should_receive(:new).with(@parameters)
      
      client = Stomp::Client.new(url)
      client.parameters.should == @parameters
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
      
      Stomp::Connection.should_receive(:new).with(@parameters)
      
      client = Stomp::Client.new(url)
      client.parameters.should == @parameters
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
end
