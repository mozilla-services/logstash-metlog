Deprecated Input Plugins
========================

zeromq_hs configuration
-----------------------

The zeromq_hs input plugin is provides a simple handshake service
which exposes a ZMQ::REP socket that is used to synchronize the
PUB/SUB 0mq input plugin.  This plugin is only required if Metlog has
declared a sender type of ZmqHandshakePubSender.

Using the zeromq_hs plugin requires setting a 0mq address so to bind a
socket.  All other required keys are inherited from the base input
plugin from logstash. ::

    input {
        zeromq_hs {
           # Setup a ZMQ::REP socket that listens on port 5180
           type => "metlog"
           mode => "server"
           address => "tcp://*:5180"
        }
    }

metlog_sentry
-------------

This output plugin is deprecated and no longer supported
