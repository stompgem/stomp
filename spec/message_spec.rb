# -*- encoding: utf-8 -*-

require 'spec_helper'

describe Stomp::Message do

  context 'when initializing a new message' do

    context 'with invalid parameters' do
      it 'should return an empty message when receiving an empty string or nil parameter' do
        message = Stomp::Message.new('')
        expect(message).to be_empty
        # message.should be_empty
      end

      it 'should raise Stomp::Error::InvalidFormat when receiving a invalid formated message' do
        expect{ Stomp::Message.new('any invalid format') }.to raise_error(Stomp::Error::InvalidFormat)
      end
    end

    context 'with valid parameters' do
      subject do
        @message = ["CONNECTED\n", "session:host_address\n", "\n", "body value\n", "\000\n"]
        Stomp::Message.new(@message.join)
      end

      it 'should parse the headers' do
        expect(subject.headers).to eq({'session' => 'host_address'})
      end

      it 'should parse the body' do
        expect(subject.body).to eq(@message[3])
      end

      it 'should parse the command' do
        expect(subject.command).to eq(@message[0].chomp)
      end
    end
    
    context 'with multiple line ends on the body' do
      subject do
        @message = ["CONNECTED\n", "session:host_address\n", "\n", "body\n\n value\n\n\n", "\000\n"]
        Stomp::Message.new(@message.join)
      end

      it 'should parse the headers' do
        expect(subject.headers).to eq({'session' => 'host_address'})
      end

      it 'should parse the body' do
        expect(subject.body).to eq(@message[3])
      end

      it 'should parse the command' do
        expect(subject.command).to eq(@message[0].chomp)
      end
    end
  end
end
