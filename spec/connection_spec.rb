# encoding: UTF-8
require 'spec_helper'

describe Stomp::Connection do

  before(:each) do
    @parameters = {
      :hosts => [
        {:login => "login1", :passcode => "passcode1", :host => "localhost", :port => 61616, :ssl => false},
        {:login => "login2", :passcode => "passcode2", :host => "remotehost", :port => 61617, :ssl => false}
      ],
      :initial_reconnect_delay => 0.01,
      :max_reconnect_delay => 30.0,
      :use_exponential_back_off => true,
      :back_off_multiplier => 2,
      :max_reconnect_attempts => 0,
      :randomize => false,
      :backup => false,
      :timeout => -1,
      :parse_timeout => 5,
      :connect_headers => {}
    }
        
    #POG:
    class Stomp::Connection
      def _receive( s )
      end
    end
    
    # clone() does a shallow copy, we want a deep one so we can garantee the hosts order
    normal_parameters = Marshal::load(Marshal::dump(@parameters))

    @tcp_socket = mock(:tcp_socket, :close => nil, :puts => nil, :write => nil, :setsockopt => nil)
    TCPSocket.stub!(:open).and_return @tcp_socket
    @connection = Stomp::Connection.new(normal_parameters)
  end
  
  describe "(created using a hash)" do
    it "should uncamelize and symbolize the main hash keys" do
      used_hash = {
        "hosts" => [
          {:login => "login2", :passcode => "passcode2", :host => "remotehost", :port => 61617, :ssl => false},
          {:login => "login1", :passcode => "passcode1", :host => "localhost", :port => 61616, :ssl => false}
        ],
        "initialReconnectDelay" => 0.01,
        "maxReconnectDelay" => 30.0,
        "useExponentialBackOff" => true,
        "backOffMultiplier" => 2,
        "maxReconnectAttempts" => 0,
        "randomize" => false,
        "backup" => false,
        "timeout" => -1,
        "parse_timeout" => 5,
      }
      
      @connection = Stomp::Connection.new(used_hash)
      @connection.instance_variable_get(:@parameters).should == @parameters
    end
    
    it "should be reliable" do
      @connection.instance_variable_get(:@reliable).should be_true
    end
    it "should start with first host in array" do
      @connection.instance_variable_get(:@host).should == "localhost"
    end
    
    it "should change host to next one with randomize false" do
      @connection.change_host
      @connection.instance_variable_get(:@host).should == "remotehost"
    end
    
    it "should use default port (61613) if none is given" do
      hash = {:hosts => [{:login => "login2", :passcode => "passcode2", :host => "remotehost", :ssl => false}]}
      @connection = Stomp::Connection.new hash
      @connection.instance_variable_get(:@port).should == 61613
    end
    
    context "when dealing with content-length header" do
      it "should not suppress it when receiving :suppress_content_length => false" do
        @tcp_socket.should_receive(:puts).with("content-length:7")
        @connection.publish "/queue", "message", :suppress_content_length => false
      end
      
      it "should not suppress it when :suppress_content_length is nil" do
        @tcp_socket.should_receive(:puts).with("content-length:7")
        @connection.publish "/queue", "message"
      end
    
      it "should suppress it when receiving :suppress_content_length => true" do
        @tcp_socket.should_not_receive(:puts).with("content-length:7")
        @connection.publish "/queue", "message", :suppress_content_length => true
      end
      
      it "should get the correct byte length when dealing with Unicode characters" do
        @tcp_socket.should_receive(:puts).with("content-length:18")
        @connection.publish "/queue", "сообщение"  # 'сообщение' is 'message' in Russian
      end
    end
    
    describe "when unacknowledging a message" do
      
      before :each do
        @message = Stomp::Message.new(nil)
        @message.body = "message body"
        @message.headers = {"destination" => "/queue/original", "message-id" => "ID"}
        
        @transaction_id = "transaction-#{@message.headers["message-id"]}-0"
        
        @retry_headers = {
          :destination => @message.headers["destination"],
          :transaction => @transaction_id,
          :retry_count => 1
        }
      end
      
      it "should use a transaction" do
        @connection.should_receive(:begin).with(@transaction_id).ordered
        @connection.should_receive(:commit).with(@transaction_id).ordered
        @connection.unreceive @message
      end
    
      it "should acknowledge the original message if ack mode is client" do
        @connection.should_receive(:ack).with(@message.headers["message-id"], :transaction => @transaction_id)
        @connection.subscribe(@message.headers["destination"], :ack => "client")
        @connection.unreceive @message
      end
      
      it "should acknowledge the original message if forced" do      
        @connection.subscribe(@message.headers["destination"])
        @connection.should_receive(:ack)
        @connection.unreceive(@message, :force_client_ack => true)
      end
      
      it "should not acknowledge the original message if ack mode is not client or it did not subscribe to the queue" do      
        @connection.subscribe(@message.headers["destination"], :ack => "client")
        @connection.should_receive(:ack)
        @connection.unreceive @message
        
        # At this time the message headers are symbolized
        @connection.unsubscribe(@message.headers[:destination])
        @connection.should_not_receive(:ack)
        @connection.unreceive @message
        @connection.subscribe(@message.headers[:destination], :ack => "individual")
        @connection.unreceive @message
      end
      
      it "should send the message back to the queue it came" do
        @connection.subscribe(@message.headers["destination"], :ack => "client")
        @connection.should_receive(:publish).with(@message.headers["destination"], @message.body, @retry_headers)
        @connection.unreceive @message
      end
      
      it "should increment the retry_count header" do
        @message.headers["retry_count"] = 4
        @connection.unreceive @message
        @message.headers[:retry_count].should == 5
      end
      
      it "should not send the message to the dead letter queue as persistent if redeliveries equal max redeliveries" do
        max_redeliveries = 5
        dead_letter_queue = "/queue/Dead"
        
        @message.headers["retry_count"] = max_redeliveries
        transaction_id = "transaction-#{@message.headers["message-id"]}-#{@message.headers["retry_count"]}"
        @retry_headers = @retry_headers.merge :transaction => transaction_id, :retry_count => @message.headers["retry_count"] + 1
        @connection.should_receive(:publish).with(@message.headers["destination"], @message.body, @retry_headers)
        @connection.unreceive @message, :dead_letter_queue => dead_letter_queue, :max_redeliveries => max_redeliveries
      end
      
      it "should send the message to the dead letter queue as persistent if max redeliveries have been reached" do
        max_redeliveries = 5
        dead_letter_queue = "/queue/Dead"
        
        @message.headers["retry_count"] = max_redeliveries + 1
        transaction_id = "transaction-#{@message.headers["message-id"]}-#{@message.headers["retry_count"]}"
        @retry_headers = @retry_headers.merge :persistent => true, :transaction => transaction_id, :retry_count => @message.headers["retry_count"] + 1, :original_destination=> @message.headers["destination"]
        @connection.should_receive(:publish).with(dead_letter_queue, @message.body, @retry_headers)
        @connection.unreceive @message, :dead_letter_queue => dead_letter_queue, :max_redeliveries => max_redeliveries
      end
      
      it "should rollback the transaction and raise the exception if happened during transaction" do
        @connection.should_receive(:publish).and_raise "Error"
        @connection.should_receive(:abort).with(@transaction_id)
        lambda {@connection.unreceive @message}.should raise_error("Error")
      end
    
    end
    
    describe "when using ssl" do

      # Mocking ruby's openssl extension, so we can test without requiring openssl  
      module ::OpenSSL
        module SSL
          VERIFY_NONE = 0
          
          class SSLSocket
          end
          
          class SSLContext
            attr_accessor :verify_mode
          end
        end
      end
      
      before(:each) do
        ssl_parameters = {:hosts => [{:login => "login2", :passcode => "passcode2", :host => "remotehost", :ssl => true}]}
        @ssl_socket = mock(:ssl_socket, :puts => nil, :write => nil, :setsockopt => nil)
        
        TCPSocket.should_receive(:open).and_return @tcp_socket
        OpenSSL::SSL::SSLSocket.should_receive(:new).and_return(@ssl_socket)
        @ssl_socket.should_receive(:connect)
        
        @connection = Stomp::Connection.new ssl_parameters
      end
    
      it "should use ssl socket if ssl use is enabled" do
        @connection.instance_variable_get(:@socket).should == @ssl_socket
      end
    
      it "should use default port for ssl (61612) if none is given" do
        @connection.instance_variable_get(:@port).should == 61612
      end
      
    end

    describe "when called to increase reconnect delay" do
      it "should exponentialy increase when use_exponential_back_off is true" do
        @connection.increase_reconnect_delay.should == 0.02
        @connection.increase_reconnect_delay.should == 0.04
        @connection.increase_reconnect_delay.should == 0.08
      end
      it "should not increase when use_exponential_back_off is false" do
        @parameters[:use_exponential_back_off] = false
        @connection = Stomp::Connection.new(@parameters)
        @connection.increase_reconnect_delay.should == 0.01
        @connection.increase_reconnect_delay.should == 0.01
      end
      it "should not increase when max_reconnect_delay is reached" do
        @parameters[:initial_reconnect_delay] = 8.0
        @connection = Stomp::Connection.new(@parameters)
        @connection.increase_reconnect_delay.should == 16.0
        @connection.increase_reconnect_delay.should == 30.0
      end
      
      it "should change to next host on socket error" do
        @connection.instance_variable_set(:@failure, "some exception")
        #retries the same host
        TCPSocket.should_receive(:open).and_raise "exception"
        #tries the new host
        TCPSocket.should_receive(:open).and_return @tcp_socket

        @connection.socket
        @connection.instance_variable_get(:@host).should == "remotehost"
      end
      
      it "should use default options if those where not given" do
        expected_hash = {
          :hosts => [
            {:login => "login2", :passcode => "passcode2", :host => "remotehost", :port => 61617, :ssl => false},
            # Once connected the host is sent to the end of array
            {:login => "login1", :passcode => "passcode1", :host => "localhost", :port => 61616, :ssl => false}
          ],
          :initial_reconnect_delay => 0.01,
          :max_reconnect_delay => 30.0,
          :use_exponential_back_off => true,
          :back_off_multiplier => 2,
          :max_reconnect_attempts => 0,
          :randomize => false,
          :backup => false,
          :timeout => -1,
          :parse_timeout => 5,
          :connect_headers => {}
        }
        
        used_hash =  {
          :hosts => [
            {:login => "login1", :passcode => "passcode1", :host => "localhost", :port => 61616, :ssl => false},
            {:login => "login2", :passcode => "passcode2", :host => "remotehost", :port => 61617, :ssl => false}
          ]
        }
        
        @connection = Stomp::Connection.new(used_hash)
        @connection.instance_variable_get(:@parameters).should == expected_hash
      end
      
      it "should use the given options instead of default ones" do
        used_hash = {
          :hosts => [
            {:login => "login2", :passcode => "passcode2", :host => "remotehost", :port => 61617, :ssl => false},
            {:login => "login1", :passcode => "passcode1", :host => "localhost", :port => 61616, :ssl => false}
          ],
          :initial_reconnect_delay => 5.0,
          :max_reconnect_delay => 100.0,
          :use_exponential_back_off => false,
          :back_off_multiplier => 3,
          :max_reconnect_attempts => 10,
          :randomize => true,
          :backup => false,
          :timeout => -1,
          :parse_timeout => 20,
          :connect_headers => {:lerolero => "ronaldo"},
          :dead_letter_queue => "queue/Error",
          :max_redeliveries => 10
        }
        
        @connection = Stomp::Connection.new(used_hash)
        received_hash = @connection.instance_variable_get(:@parameters)
        
        #Using randomize we can't assure the hosts order
        received_hash.delete(:hosts)
        used_hash.delete(:hosts)
        
        received_hash.should == used_hash
      end
      
    end
    
  end
  
  describe "when closing a socket" do
    it "should close the tcp connection" do
      @tcp_socket.should_receive(:close)
      @connection.obj_send(:close_socket).should be_true
    end
    it "should ignore exceptions" do
      @tcp_socket.should_receive(:close).and_raise "exception"
      @connection.obj_send(:close_socket).should be_true
    end
  end

  describe "when checking if max reconnect attempts have been reached" do
    it "should return false if not using failover" do
      host = @parameters[:hosts][0]
      @connection = Stomp::Connection.new(host[:login], host[:passcode], host[:host], host[:port], reliable = true, 5, connect_headers = {})
      @connection.instance_variable_set(:@connection_attempts, 10000)
      @connection.max_reconnect_attempts?.should be_false
    end
    it "should return false if max_reconnect_attempts = 0" do
      @connection.instance_variable_set(:@connection_attempts, 10000)
      @connection.max_reconnect_attempts?.should be_false
    end
    it "should return true if connection attempts > max_reconnect_attempts" do
      limit = 10000
      @parameters[:max_reconnect_attempts] = limit
      @connection = Stomp::Connection.new(@parameters)
      
      @connection.instance_variable_set(:@connection_attempts, limit-1)
      @connection.max_reconnect_attempts?.should be_false
      
      @connection.instance_variable_set(:@connection_attempts, limit)
      @connection.max_reconnect_attempts?.should be_true
      
    end
  end
end

