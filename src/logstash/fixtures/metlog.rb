require 'logstash'

require "logstash/event"


module LogStash::Fixtures
    # This module is literally just test fixture data
    # We want to curate sample data that can be reused by multiple
    # test cases, or at the least have a single place to look when
    # determining what data we are actually testing with
    class MetlogFixtures
        @@stack_error = {
            'timestamp' => '2011-10-13T09:43:44.386392',
            'metadata' => {'some_data' => 'foo' },
            'type' => 'error',
            'logger' => 'stacktrace',
            'severity' => 0,
            'message' => 'some log text',
            'payload' => 'blah blah',
        }


        public
        def self.stack_error
            @@stack_error
        end

        @@stackerror_event = nil
        public
        def self.stackerror_event
            event = LogStash::Event.new
            event.fields['timestamp'] = '2011-10-13T09:43:44.386392'
            event.fields['fields'] = {'some_data' => 'foo' }
            event.fields['type'] = 'error'
            event.fields['logger'] = 'stacktrace'
            event.fields['severity'] = 0
            event.fields['payload'] = 'some log text'
            return event
        end


        # This is a basic increment
        public
        def self.simple_incr_counter
            evt = LogStash::Event.new
            evt.fields['logger'] = 'incr-space'
            evt.fields['fields'] = {}
            evt.fields['fields']['name'] = 'myapp'
            evt.fields['payload'] = '2'
            evt.fields['fields']['rate'] = 1
            return evt
        end

        # This is a sampled increment
        public
        def self.sampled_incr_counter
            evt = LogStash::Event.new
            evt.fields['logger'] = 'incr-space'
            evt.fields['fields'] = {}
            evt.fields['fields']['name'] = 'my_sampleapp'
            evt.fields['payload'] = 7
            evt.fields['fields']['rate'] = 0.15
            return evt
        end

        # This is a timed event
        public
        def self.timing_event
            evt = LogStash::Event.new
            evt.fields['logger'] = 'timing-space'
            evt.fields['fields'] = {}
            evt.fields['fields']['name'] = 'my_timing'
            evt.fields['payload'] = 7
            evt.fields['fields']['rate'] = 1
            return evt
        end

        # This is a sampled timed event
        public
        def self.sampled_timing_event
            evt = LogStash::Event.new
            evt.fields['logger'] = 'timing-space'
            evt.fields['fields'] = {}
            evt.fields['fields']['name'] = 'my_sampletiming'
            evt.fields['payload'] = 7
            evt.fields['fields']['rate'] = 0.15
            return evt
        end

        # This is a malformed event in the context of metlog-statsd
        public
        def self.malformed_statsd_event
            evt = LogStash::Event.new
            evt.fields['logger'] = 'malformed'
            evt.fields['fields'] = {}

            # Skip the app name - this should cause the statsd
            # client to not push the event
            # evt.fields['fields']['name'] = 'my_sampletiming'

            evt.fields['payload'] = 7
            evt.fields['fields']['rate'] = 0.15
            return evt
        end

    end
end
