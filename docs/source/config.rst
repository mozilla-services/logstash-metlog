====================
Plugin Configuration
====================

Metlog provides some plugins to ease integration with logstash.

Input plugins provided:

    * logstash.inputs.udp
    * logstash.inputs.zeromq_hs (deprecated)

Filter plugins provided:

    * logstash.filters.tagger
    * logstash.filters.catchall

Output plugins provided:

    * logstash.outputs.metlog_cef
    * logstash.outputs.metlog_file
    * logstash.outputs.metlog_sentry_dsn
    * logstash.outputs.metlog_statsd
    * logstash.outputs.metlog_sentry (deprecated)

Input plugins
=============

udp
---

The udp input plugin provides a basic UDP listener service for
logstash.

Messages may be lost using this input listener, and messages greater
than 64kb may be truncated.

For typical configuration, you need to only care about the host and
port that the listener will operate on.  A typical configuration block
will look like this ::

    udp {
        type => "metlog"
        mode => "server"
        format => "json"

        host => "0.0.0.0"
        port => 5565
    }

The above configuration will let logstash listen on all network
interfaces on port 5565.  

The type, mode and format should always be set to "metlog", "server"
and "json" as per the example.


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
            pattern => [ "type", "timer"]
            add_tag => [ "output_statsd" ]
        }
    }

If a keypath does not exist within an event, it is ignored.

Multiple keypaths can be defined using a flattened key/value mapping
as shown in the following example.

If the file type is either a 'timer' or 'counter', the 'output_statsd'
tag will be applied. ::

    filter {
        tagger {
            # all timer and counter messages are tagged with 'output_statsd'
            type => "metlog"
            pattern => [ "type", "timer", "type", "counter" ]
            add_tag => [ "output_statsd" ]
        }
    }

catchall configuration
----------------------

The catchall filter is used to select messages which have not been
previously tagged by another filter.  This only works properly because
the Logstash FilterWorker pool processes messages serially through
each of the filters defined in logstash.conf

Unfortunately, filters cannot see configuration from other filters so
you must specify the set of tags which indicate that the message has
been successfully filtered.

The catchall should specify the superset of all tags
which logstash should care about.  A logstash event must match *none*
of the tags in this superset for the catchall filter to add the
'filter-catchall' tag to the event.

A typical configuration block is shown below ::

    catchall {
        # anything that isn't tagged already gets tagged here
        tags => [ "output_text", "output_statsd", "output_sentry", "output_cef" ]
        add_tag => ['filter-catchall']
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


metlog_cef configuration
------------------------

CEF messages are routed to the syslog daemon running on the local
machine.  The only configuration you need is the tag that a logstash
event must have to route to this output.

A typical configuration block is below ::

    metlog_cef {
        # CEF gets routed over syslog
        tags => ["output_cef"]
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
        prefix_timestamps => true
        formatted_field => "payload"
        path => "/var/log/metlog/metlog_classic.log"
    }

If you need to address a different part of the logstash event, simply
use '/' notation. ::

    metlog_file {
        tags => ["output_some_random_text"]
        format => "preformatted_field"
        formatted_field => "fields/logtext"
        path => "/var/log/metlog/metlog_some_random_text.log"
    }

metlog_sentry_dsn
-----------------

The metlog_sentry_dsn output plugin relies on metlog using
metlog-raven >= 0.3.  The metlog client will embed the sentry DSN which
we want to use for final routing.  The only configuration you need
is the tag that a logstash event must have to route to this output.

A typical configuration block is below ::

    metlog_sentry_dsn {
        # This is a new Sentry output plugin which requires the
        # metlog-raven client to embed the DSN in the metlog message
        tags => [ "output_sentry" ]
    }


A complete configuration
------------------------

Tying all these parts together is sometimes not entirely obvious, so
we've assembled a working vagrant image for you.  You can go use our
`vagrant backend
<https://github.com/mozilla-services/vagrant-metlog-backend/>`_ to get
a working enviroment.

The `logstash configuration <https://github.com/mozilla-services/vagrant-metlog-backend/blob/master/files/logstash.conf>`_ for that instance can always be used as a
reference point for a working configuration.
