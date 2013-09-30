# -*- encoding: utf-8 -*-

#   Copyright 2005-2006 Brian McCallister
#   Copyright 2006 LogicBlaze Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

require 'stomp/constants'       # Constants first
require 'stomp/ext/hash'        # #Hash additions
require 'stomp/connection'      # Main Stomp#Connection
require 'stomp/client'          # Main Stomp#Client
require 'stomp/message'         # Stomp#Message
require 'stomp/version'         # Stomp#Version#STRING
require 'stomp/errors'          # All Stomp# exceptions
require 'stomp/codec'           # Stomp 1.1 codec
require 'stomp/sslparams'       # Stomp SSL support
require 'stomp/null_logger'     # A NullLogger class

# Private methods in #Client
require 'client/utils'          # private Client Utility methods

# Private methods in #Connection
require 'connection/utils'      # private Connection Utility methods
require 'connection/netio'      # private Network io methods
require 'connection/heartbeats' # private 1.1+ heartbeat related methods
require 'connection/utf8'       # private 1.1+ UTF8 related methods

module Stomp
end

