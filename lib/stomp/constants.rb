# -*- encoding: utf-8 -*-

module Stomp

  # Client generated frames
  CMD_CONNECT     = "CONNECT"
  CMD_STOMP       = "STOMP"
  CMD_DISCONNECT  = "DISCONNECT"
  CMD_SEND        = "SEND"
  CMD_SUBSCRIBE   = "SUBSCRIBE"
  CMD_UNSUBSCRIBE = "UNSUBSCRIBE"
  CMD_ACK         = "ACK"
  CMD_NACK        = "NACK"
  CMD_BEGIN       = "BEGIN"
  CMD_COMMIT      = "COMMIT"
  CMD_ABORT       = "ABORT"

  # Server generated names
  CMD_CONNECTED = "CONNECTED"
  CMD_MESSAGE   = "MESSAGE"
  CMD_RECEIPT   = "RECEIPT"
  CMD_ERROR     = "ERROR"

  # Protocols
  SPL_10 = "1.0"
  SPL_11 = "1.1"
  SPL_12 = "1.2"

  # Stomp 1.0 and 1.1 and 1.2
  SUPPORTED = [SPL_10, SPL_11, SPL_12]

  # UTF-8 Encoding Name
  UTF8 = "UTF-8"
  #
  # Octet 0
  #
  NULL = "\0"
  #
  # New line
  #
  NL = "\n"
  NL_ASCII = 0x0a
  #
  # Line Feed (New Line)
  #
  LF = "\n"
  LF_ASCII = 0x0a
  #
  # New line
  #
  CR = "\r"
  CR_ASCII = 0x0d
  #
  # Back Slash
  #
  BACK_SLASH = "\\"
  BACK_SLASH_ASCII = 0x5c
  #
  # Literal colon
  #
  LITERAL_COLON = ":"
  COLON_ASCII = 0x3a
  #
  # Literal letter c
  #
  LITERAL_C = "c"
  C_ASCII = 0x63
  #
  # Literal letter n
  #
  LITERAL_N = "n"
  N_ASCII = 0x6e
  #
  # Codec from/to values.
  #
  ENCODE_VALUES = [
    "\\\\\\\\", "\\", # encoded, decoded
    "\\" + "n", "\n",
    "\\" + "r", "\r",
    "\\c", ":",
  ]

  #
  DECODE_VALUES = [
    "\\\\", "\\", # encoded, decoded
    "\\" + "n", "\n",
    "\\" + "r", "\r",
    "\\c", ":",
  ]

  # A fairly safe and generally supported ciphers list.
  DEFAULT_CIPHERS = [
    ["AES128-GCM-SHA256","TLSv1/SSLv3",128,128],
    ["AES128-SHA256","TLSv1/SSLv3",128,128],
    ["AES128-SHA","TLSv1/SSLv3",128,128],
    ["AES256-GCM-SHA384","TLSv1/SSLv3",256,256],
    ["AES256-SHA256","TLSv1/SSLv3",256,256],
    ["AES256-SHA","TLSv1/SSLv3",256,256],
    ["CAMELLIA128-SHA","TLSv1/SSLv3",128,128],
    ["CAMELLIA256-SHA","TLSv1/SSLv3",256,256],
    ["DES-CBC3-SHA","TLSv1/SSLv3",168,168],
    ["DES-CBC-SHA","TLSv1/SSLv3",56,56],
    ["DHE-DSS-AES128-GCM-SHA256","TLSv1/SSLv3",128,128],
    ["DHE-DSS-AES128-SHA256","TLSv1/SSLv3",128,128],
    ["DHE-DSS-AES128-SHA","TLSv1/SSLv3",128,128],
    ["DHE-DSS-AES256-GCM-SHA384","TLSv1/SSLv3",256,256],
    ["DHE-DSS-AES256-SHA256","TLSv1/SSLv3",256,256],
    ["DHE-DSS-AES256-SHA","TLSv1/SSLv3",256,256],
    ["DHE-DSS-CAMELLIA128-SHA","TLSv1/SSLv3",128,128],
    ["DHE-DSS-CAMELLIA256-SHA","TLSv1/SSLv3",256,256],
    ["DHE-DSS-SEED-SHA","TLSv1/SSLv3",128,128],
    ["DHE-RSA-AES128-GCM-SHA256","TLSv1/SSLv3",128,128],
    ["DHE-RSA-AES128-SHA256","TLSv1/SSLv3",128,128],
    ["DHE-RSA-AES128-SHA","TLSv1/SSLv3",128,128],
    ["DHE-RSA-AES256-GCM-SHA384","TLSv1/SSLv3",256,256],
    ["DHE-RSA-AES256-SHA256","TLSv1/SSLv3",256,256],
    ["DHE-RSA-AES256-SHA","TLSv1/SSLv3",256,256],
    ["DHE-RSA-CAMELLIA128-SHA","TLSv1/SSLv3",128,128],
    ["DHE-RSA-CAMELLIA256-SHA","TLSv1/SSLv3",256,256],
    ["DHE-RSA-SEED-SHA","TLSv1/SSLv3",128,128],
    ["ECDH-ECDSA-AES128-GCM-SHA256","TLSv1/SSLv3",128,128],
    ["ECDH-ECDSA-AES128-SHA256","TLSv1/SSLv3",128,128],
    ["ECDH-ECDSA-AES128-SHA","TLSv1/SSLv3",128,128],
    ["ECDH-ECDSA-AES256-GCM-SHA384","TLSv1/SSLv3",256,256],
    ["ECDH-ECDSA-AES256-SHA384","TLSv1/SSLv3",256,256],
    ["ECDH-ECDSA-AES256-SHA","TLSv1/SSLv3",256,256],
    ["ECDH-ECDSA-DES-CBC3-SHA","TLSv1/SSLv3",168,168],
    ["ECDH-ECDSA-RC4-SHA","TLSv1/SSLv3",128,128],
    ["ECDHE-ECDSA-AES128-GCM-SHA256","TLSv1/SSLv3",128,128],
    ["ECDHE-ECDSA-AES128-SHA256","TLSv1/SSLv3",128,128],
    ["ECDHE-ECDSA-AES128-SHA","TLSv1/SSLv3",128,128],
    ["ECDHE-ECDSA-AES256-GCM-SHA384","TLSv1/SSLv3",256,256],
    ["ECDHE-ECDSA-AES256-SHA384","TLSv1/SSLv3",256,256],
    ["ECDHE-ECDSA-AES256-SHA","TLSv1/SSLv3",256,256],
    ["ECDHE-ECDSA-DES-CBC3-SHA","TLSv1/SSLv3",168,168],
    ["ECDHE-ECDSA-RC4-SHA","TLSv1/SSLv3",128,128],
    ["ECDHE-RSA-AES128-GCM-SHA256","TLSv1/SSLv3",128,128],
    ["ECDHE-RSA-AES128-SHA256","TLSv1/SSLv3",128,128],
    ["ECDHE-RSA-AES128-SHA","TLSv1/SSLv3",128,128],
    ["ECDHE-RSA-AES256-GCM-SHA384","TLSv1/SSLv3",256,256],
    ["ECDHE-RSA-AES256-SHA384","TLSv1/SSLv3",256,256],
    ["ECDHE-RSA-AES256-SHA","TLSv1/SSLv3",256,256],
    ["ECDHE-RSA-DES-CBC3-SHA","TLSv1/SSLv3",168,168],
    ["ECDHE-RSA-RC4-SHA","TLSv1/SSLv3",128,128],
    ["ECDH-RSA-AES128-GCM-SHA256","TLSv1/SSLv3",128,128],
    ["ECDH-RSA-AES128-SHA256","TLSv1/SSLv3",128,128],
    ["ECDH-RSA-AES128-SHA","TLSv1/SSLv3",128,128],
    ["ECDH-RSA-AES256-GCM-SHA384","TLSv1/SSLv3",256,256],
    ["ECDH-RSA-AES256-SHA384","TLSv1/SSLv3",256,256],
    ["ECDH-RSA-AES256-SHA","TLSv1/SSLv3",256,256],
    ["ECDH-RSA-DES-CBC3-SHA","TLSv1/SSLv3",168,168],
    ["ECDH-RSA-RC4-SHA","TLSv1/SSLv3",128,128],
    ["EDH-DSS-DES-CBC3-SHA","TLSv1/SSLv3",168,168],
    ["EDH-DSS-DES-CBC-SHA", "TLSv1/SSLv3", 56, 56],
    ["EDH-DSS-DES-CBC-SHA","TLSv1/SSLv3",56,56],
    ["EDH-RSA-DES-CBC3-SHA","TLSv1/SSLv3",168,168],
    ["EDH-RSA-DES-CBC-SHA","TLSv1/SSLv3",56,56],
    ["EXP-DES-CBC-SHA","TLSv1/SSLv3",40,56],
    ["EXP-EDH-DSS-DES-CBC-SHA","TLSv1/SSLv3",40,56],
    ["EXP-EDH-RSA-DES-CBC-SHA","TLSv1/SSLv3",40,56],
    ["EXP-RC2-CBC-MD5","TLSv1/SSLv3",40,128],
    ["EXP-RC4-MD5", "TLSv1/SSLv3", 40, 128],
    ["PSK-3DES-EDE-CBC-SHA","TLSv1/SSLv3",168,168],
    ["PSK-AES128-CBC-SHA","TLSv1/SSLv3",128,128],
    ["PSK-AES256-CBC-SHA","TLSv1/SSLv3",256,256],
    ["PSK-RC4-SHA","TLSv1/SSLv3",128,128],
    ["RC4-MD5","TLSv1/SSLv3",128,128],
    ["RC4-SHA","TLSv1/SSLv3",128,128],
    ["SEED-SHA","TLSv1/SSLv3",128,128],
    ["SRP-DSS-3DES-EDE-CBC-SHA","TLSv1/SSLv3",168,168],
    ["SRP-DSS-AES-128-CBC-SHA","TLSv1/SSLv3",128,128],
    ["SRP-DSS-AES-256-CBC-SHA","TLSv1/SSLv3",256,256],
    ["SRP-RSA-3DES-EDE-CBC-SHA","TLSv1/SSLv3",168,168],
    ["SRP-RSA-AES-128-CBC-SHA","TLSv1/SSLv3",128,128],
    ["SRP-RSA-AES-256-CBC-SHA","TLSv1/SSLv3",256,256],
  ]

  HAND_SHAKE_DATA = "\x15\x03\x03\x00\x02\x02\n"

  original_verbose, $VERBOSE = $VERBOSE, nil # try to shut off warnings

  # stomp URL regex pattern, for e.g. login:passcode@host:port or host:port
  URL_REPAT = '((([\w~!@#$%^&*()\-+=.?:<>,.]*\w):([\w~!@#$%^&*()\-+=.?:<>,.]*))?@)?([\w\.\-]+):(\d+)'

  # Failover URL regex, for e.g.
  #failover:(stomp+ssl://login1:passcode1@remotehost1:61612,stomp://login2:passcode2@remotehost2:61613)
  FAILOVER_REGEX = /^failover:(\/\/)?\(stomp(\+ssl)?:\/\/#{URL_REPAT}(,stomp(\+ssl)?:\/\/#{URL_REPAT})*\)(\?(.*))?$/

  $VERBOSE = original_verbose

end # Module Stomp
