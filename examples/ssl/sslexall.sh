#!/bin/sh
#
ruby -I ../../lib uc1/ssl_uc1.rb
echo "=============================="
ruby -I ../../lib uc1/ssl_uc1_ciphers.rb
echo "=============================="
ruby -I ../../lib uc2/ssl_uc2.rb
echo "=============================="
ruby -I ../../lib uc2/ssl_uc2_ciphers.rb
echo "=============================="
ruby -I ../../lib uc3/ssl_uc3.rb
echo "=============================="
ruby -I ../../lib uc3/ssl_uc3_ciphers.rb
echo "=============================="
ruby -I ../../lib uc4/ssl_uc4.rb
echo "=============================="
ruby -I ../../lib uc4/ssl_uc4_ciphers.rb
