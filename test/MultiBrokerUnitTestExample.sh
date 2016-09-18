#!/bin/sh
#
set -x
#
# An example of running unit tests against multiple message brokers.
#
pref="STOMP_PORT=61613 rake test --trace"
echo =============== AMQ Stomp 1.0 ===============
eval $pref

pref="STOMP_PORT=61613 STOMP_TEST11p=1.1 STOMP_AMQ11=y STOMP_NOWILD=y rake test --trace"
echo =============== AMQ Stomp 1.1 ===============
eval $pref

pref="STOMP_PORT=61613 STOMP_TEST11p=1.2 STOMP_AMQ11=y STOMP_NOWILD=y rake test --trace"
echo =============== AMQ Stomp 1.2 ===============
eval $pref

pref="STOMP_TESTSSL=y STOMP_PORT=62613 STOMP_SSLPORT=62614 STOMP_DOTQUEUE=y STOMP_NOWILD=y rake test --trace"
echo =============== Apollo Stomp 1.0 ===============
eval $pref

pref="STOMP_TESTSSL=y STOMP_PORT=62613 STOMP_SSLPORT=62614 STOMP_DOTQUEUE=y STOMP_TEST11p=1.1 STOMP_NOWILD=y STOMP_APOLLO=y rake test --trace"
echo =============== Apollo Stomp 1.1 ===============
eval $pref

pref="STOMP_TESTSSL=y STOMP_PORT=62613 STOMP_SSLPORT=62614 STOMP_DOTQUEUE=y STOMP_TEST11p=1.2 STOMP_NOWILD=y STOMP_APOLLO=y rake test --trace"
echo =============== Apollo Stomp 1.2 ===============
eval $pref

pref="STOMP_TESTSSL=y STOMP_PORT=62613 STOMP_SSLPORT=62614 STOMP_DOTQUEUE=y STOMP_TEST11p=1.2 STOMP_NOWILD=y STOMP_CRLF=y STOMP_APOLLO=y rake test --trace"
echo =============== Apollo Stomp 1.2 - CRLF=y ===============
eval $pref

pref="STOMP_TESTSSL=y STOMP_PORT=62613 STOMP_SSLPORT=62614 STOMP_DOTQUEUE=y STOMP_TEST11p=1.2 STOMP_NOWILD=y STOMP_CONN=y STOMP_APOLLO=y rake test --trace"
echo =============== Apollo Stomp 1.2 - CONN=y ===============
eval $pref

pref="STOMP_RABBIT=y STOMP_PORT=41613 STOMP_DOTQUEUE=y STOMP_NOWILD=y rake test --trace"
echo =============== RabbitMQ Stomp 1.0 ===============
eval $pref

pref="STOMP_RABBIT=y STOMP_PORT=41613 STOMP_DOTQUEUE=y STOMP_NOWILD=y STOMP_TEST11p=1.1 rake test --trace"
echo =============== RabbitMQ Stomp 1.1 ===============
eval $pref

pref="STOMP_RABBIT=y STOMP_PORT=41613 STOMP_DOTQUEUE=y STOMP_NOWILD=y STOMP_TEST11p=1.2 rake test --trace"
echo =============== RabbitMQ Stomp 1.2 ===============
eval $pref

pref="STOMP_ARTEMIS=y STOMP_PORT=31613 STOMP_NOWILD=y rake test --trace"
echo =============== Artemis Stomp 1.0 ===============
eval $pref

pref="STOMP_ARTEMIS=y STOMP_PORT=31613 STOMP_NOWILD=y STOMP_TEST11p=1.1 rake test --trace"
echo =============== Artemis Stomp 1.1 ===============
eval $pref

pref="STOMP_ARTEMIS=y STOMP_PORT=31613 STOMP_NOWILD=y STOMP_TEST11p=1.2 rake test --trace"
echo =============== Artemis Stomp 1.2 ===============
eval $pref

set +x
exit 0

