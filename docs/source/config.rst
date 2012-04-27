====================
Plugin Configuration
====================

Metlog provides some plugins to ease integration with logstash.

Input plugins provided:

    * logstash.inputs.zeromq_hs

Filter plugins provided:

    * logstash.filters.tagger

Output plugins provided:

    * logstash.outputs.metlog_file
    * logstash.outputs.metlog_statsd

Input plugins
=============

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

In the above example, the `type` is required by logstash.inputs.base.
It is not used by the zeromq_hs plugin.

`mode` must always be set as 'server' for the socket to bind properly.
`address` is any valid URL recognized by 0mq.

Filter plugins
==============

tagger configuration
--------------------

The tagger filter lets you define a pattern keypath into an event.
Each keypath is applied in order.  On the first match - all tags will
be applied to the event.

Keypaths are defined using a '/' notation.

One common case is to match the `type` of an event so that events are
routed to a final destination.  In the following example, we want to
route all `timer` type events to the statsd output plugin by adding 
the tag 'output_statsd' to the event. ::

    filter {
        tagger {
            # all timer messages are tagged with 'output_statsd'
            type => "metlog"
            pattern => [ "fields/type", "timer"]
            add_tag => [ "output_statsd" ]
        }
    }

If a keypath does not exist within an event, it is ignored.

Multiple keypaths can be defined as shown in the following example.
If the file type is either a 'timer' or 'counter', the 'output_statsd'
tag will be applied. ::

    filter {
        tagger {
            # all timer and counter messages are tagged with 'output_statsd'
            type => "metlog"
            pattern => [ "fields/type", "timer", "fields/type", "counter" ]
            add_tag => [ "output_statsd" ]
        }
    }


Output plugins
==============

metlog_statsd configuration
---------------------------

The standard statsd output plugin provided by logstash is designed to
repeatedly create the same kind of statsd message.

This plugin provides a basic interface to talk to a statsd server.

The plugin will map event attributes into statsd using ::

    namespace = event.fields['fields']['logger']
    key = event.fields['fields']['name']
    value = event.fields['payload'].to_f
    rate = event.fields['fields']['rate'].to_f

The default sampling rate is 1.

The value of event.fields['type'] must be one of 'counter' or 'timer'.

For counter messages, the final statsd message is constructed using ::

    `namespace`.`key`:`value`|c|`rate`

For timer messages, the final statsd message is constructed using ::

    `namespace`.`key`:`value`|ms|`rate`

Configuration of the plugin requires setting a host, port and a list
of tags which the output plugin should watch for. At least one tag
must match for the output plugin to be triggered.

The following configuration monitors only the 'output_statsd' tag and
sends statsd messages to localhost at port 8125.  ::

    output {
        metlog_statsd {
            # Route any message tagged with 'output_statsd'
            # to the statsd server
            tags => ["output_statsd"]
            host => '127.0.0.1'
            port => 8125
        }
    }


metlog_file configuration
-------------------------

This output plugin is able to output either JSON blobs or plain text.

In general, JSON file outputs are used for 

For plain text, the plugin will extract a single field in the JSON
blob and will write that out. Typically, this is the `payload` key so
your configuration will look like this ::

    metlog_file {
        # The plaintext logfile
        tags => ["output_text"]
        format => "preformatted_field"
        formatted_field => "payload"
        path => "/var/log/metlog/metlog_classic.log"
    }

If you need to address a different part of the logstash event, simply
use '/' notation. A concrete example of this is writing out CEF
messages. ::

    metlog_file {
        # CEF messages just go out to a dedicated plain text logger
        tags => ["output_cef"]
        format => "preformatted_field"
        formatted_field => "fields/logtext"
        path => "/var/log/metlog/metlog_cef.log"
    }

Log rotation is handled using logrotate to rename the file and then
sending a SIGHUP to the logstash process. A sample logrotate script is
follows ::

    "/var/log/metlog/metlog_cef.log" {
        rotate 20
        size=64M
        create
        ifempty
        daily
        postrotate
            # Send a SIGHUP to to your logstash process here
            # using whatever process management tool you happen to be
            # using
        endscript
    }
