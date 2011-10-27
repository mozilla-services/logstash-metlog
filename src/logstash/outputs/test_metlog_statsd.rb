# You'll need to import logstash for all tests to get all the logstash
# namespaces. This should always be first
require "logstash"

# You need to import both the test runner and ruby-debug
# You need these two for all test cases
require "logstash_test_runner"
require "ruby-debug"
require 'mocha'

# The plugin under test
require "logstash/outputs/metlog_statsd"

# Fixture data
require "logstash/fixtures/metlog"

describe LogStash::Outputs::MetlogStatsd do

  def init_client
      @json_blob  = JSON(LogStash::Fixtures::MetlogFixtures.stack_error).to_s

      # get a new statsd plugin each time
      cfg = {}
      cfg['tags'] = ['metlog_statsd_output']
      @plugin = LogStash::Outputs::MetlogStatsd.new(cfg)

  end

  test "simple increment" do
      # This test just makes sure that the input plugin will decode
      # JSON text blobs into event objects

      init_client

      event = LogStash::Fixtures::MetlogFixtures.simple_incr_counter

      # Patch the count and timing methods

      @plugin.instance_eval("@client").stubs(:count).with('incr-space', 'myapp', 2, 1)
      @plugin.client.stubs(:timing).never()
      @plugin.receive(event)
  end

  test "namespaced increment" do
      raise NotImplementedError
  end 

  test "sampled increment @ 10%" do
      raise NotImplementedError
  end

  test "sampled decrement @ 15%" do
      raise NotImplementedError
  end

  test "timing an event" do
      raise NotImplementedError
  end

  test "timing an event @ 18%" do
      raise NotImplementedError
  end

end # TestTagger

