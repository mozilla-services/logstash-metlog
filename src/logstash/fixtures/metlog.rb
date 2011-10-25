# This file contains some helper functions for testing
require 'logstash'


module LogStash::Fixtures
    class MetlogFixtures
        @@stack_error = {
            'timestamp' => '2011-10-13T09:43:44.386392',
            'metadata' => {'some_data' => 'foo' },
            'type' => 'error',
            'logger' => 'stacktrace',
            'severity' => 0,
            'message' => 'some log text',
        }
    end
end
