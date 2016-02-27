# -*- encoding: utf-8 -*-

module Stomp

  # Message is a container class for frames.  Misnamed technically.
  class Message

    public

    # The COMMAND value.
    attr_accessor :command

    # The Headers Hash.
    attr_accessor :headers

    # The message Body.
    attr_accessor :body

    # The original input(s).
    attr_accessor :original

    # Commands that are allowed from the wire per the specifications.
    @@allowed_commands = [ Stomp::CMD_CONNECTED, Stomp::CMD_MESSAGE, Stomp::CMD_RECEIPT, Stomp::CMD_ERROR ]

    # initialize returns a Message from a raw physical frame.
    def initialize(frame, protocol11p = false)
      # p [ "00", frame, frame.encoding ]
      # Set default empty values
      self.command = ''
      self.headers = {}
      self.body = ''
      self.original = frame
      return self if is_blank?(frame)
      # Figure out where individual parts of the frame begin and end.
      command_index = frame.index("\n")
      raise Stomp::Error::InvalidFormat, 'command index' unless command_index
      #
      headers_index = frame.index("\n\n", command_index+1)
      raise Stomp::Error::InvalidFormat, 'headers index' unless headers_index
      #
      lastnull_index = frame.rindex("\0")
      raise Stomp::Error::InvalidFormat, 'lastnull index' unless lastnull_index

      # Extract working copies of each frame part
      work_command = frame[0..command_index-1]
      raise Stomp::Error::InvalidServerCommand, "invalid command: #{work_command.inspect}" unless @@allowed_commands.include?(work_command)
      #
      work_headers = frame[command_index+1..headers_index-1]
      raise Stomp::Error::InvalidFormat, 'nil headers' unless work_headers
      #
      work_body = frame[headers_index+2..lastnull_index-1]
      raise Stomp::Error::InvalidFormat, 'nil body' unless work_body
      # Set the frame values
      if protocol11p
        work_command.force_encoding(Stomp::UTF8) if work_command.respond_to?(:force_encoding)
      end
      self.command = work_command
      work_headers.split("\n").map do |value|
        fc = value.index(":")
        raise Stomp::Error::InvalidFormat, 'parsed header value' unless fc
        #
        pk = value[0...fc]
        pv = value[fc+1..-1]
        #
        if protocol11p
          pk.force_encoding(Stomp::UTF8) if pk.respond_to?(:force_encoding)
          pv.force_encoding(Stomp::UTF8) if pv.respond_to?(:force_encoding)
          # Stomp 1.1+ - Servers may put multiple values for a single key on the wire.
          # If so, we support reading those, and passing them to the user.
          if self.headers[pk]
            if self.headers[pk].is_a?(Array) # The 3rd and any subsequent ones for this key
              self.headers[pk] << pv
            else
              # The 2nd one for this key
              tv = self.headers[pk] + ""
              self.headers[pk] = []
              self.headers[pk] << tv << pv
            end
          else
            self.headers[pk] = pv # The 1st one for this key
          end
        else
          # Stomp 1.0
          self.headers[pk.strip] = pv.strip unless self.headers[pk.strip] # Only receive the 1st one
        end
      end

      raise Stomp::Error::ProtocolErrorEmptyHeaderKey if self.headers.has_key?("")
      raise Stomp::Error::ProtocolErrorEmptyHeaderValue if (!protocol11p) && self.headers.has_value?("")

      body_length = -1

      if self.headers['content-length']
        body_length = self.headers['content-length'].to_i
        raise Stomp::Error::InvalidMessageLength if work_body.length != body_length
      end
      self.body = work_body[0..body_length]
    end

    # to_s returns a string prepresentation of this Message.
    def to_s
      "<Stomp::Message headers=#{headers.inspect} body='#{body}' command='#{command}' >"
    end

    # is_blank? tests if a data value is nil or empty.
    def is_blank?(value)
      value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end

    # empty? tests if a Message has any blank parts.
    def empty?
      is_blank?(command) && is_blank?(headers) && is_blank?(body)
    end

  end # class Message

end # module Stomp

