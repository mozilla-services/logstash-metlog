require 'logstash'


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
        }
    end
end
