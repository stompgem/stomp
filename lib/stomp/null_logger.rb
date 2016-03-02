# -*- encoding: utf-8 -*-

module Stomp
  class NullLogger
    def on_miscerr(parms, error_msg)
      $stderr.print "\non_miscerr\n"
      $stderr.print parms.inspect
      $stderr.print "\n"
      $stderr.print error_msg
      $stderr.print "\n"
    end

    def on_connecting(parms); end
    def on_connected(parms); end
    def on_connectfail(parms); end
    def on_disconnect(parms); end
    def on_subscribe(parms, headers); end
    def on_unsubscribe(parms, headers); end
    def on_publish(parms, message, headers); end
    def on_receive(parms, result); end
    def on_begin(parms, headers); end
    def on_ack(parms, headers); end
    def on_nack(parms, headers); end
    def on_commit(parms, headers); end
    def on_abort(parms, headers); end
    def on_hbread_fail(parms, ticker_data); end
    def on_hbwrite_fail(parms, ticker_data); end
    def on_ssl_connecting(parms); end
    def on_ssl_connected(parms); end
    def on_ssl_connectfail(parms); end
    def on_hbfire(parms, srind, curt); end
  end
end
