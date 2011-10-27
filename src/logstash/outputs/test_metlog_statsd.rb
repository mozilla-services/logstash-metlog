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
      init_client

      event = LogStash::Fixtures::MetlogFixtures.simple_incr_counter

      # Patch the count and timing methods

      @plugin.instance_eval("@client").stubs(:count).with(event.fields['logger'],
                                                          event.fields['fields']['name'],
                                                          event.fields['payload'].to_f,
                                                          event.fields['fields']['rate'].to_f)
      @plugin.instance_eval("@client").stubs(:timing).never()
      @plugin.receive(event)
  end

  test "sampled increment @ 15%" do
      init_client

      event = LogStash::Fixtures::MetlogFixtures.sampled_incr_counter

      # Patch the count and timing methods

      @plugin.instance_eval("@client").stubs(:count).with(event.fields['logger'],
                                                          event.fields['fields']['name'],
                                                          event.fields['payload'].to_f,
                                                          event.fields['fields']['rate'].to_f)
      @plugin.instance_eval("@client").stubs(:timing).never()
      @plugin.receive(event)
  end

  test "timing an event" do
      init_client

      event = LogStash::Fixtures::MetlogFixtures.timing_event

      # Patch the count and timing methods

      @plugin.instance_eval("@client").stubs(:count).never()
      @plugin.instance_eval("@client").stubs(:timing).with(event.fields['logger'],
                                                           event.fields['fields']['name'],
                                                           event.fields['payload'].to_f,
                                                           event.fields['fields']['rate'].to_f)
      @plugin.receive(event)
  end

  test "timing an event @ 15%" do
      init_client

      event = LogStash::Fixtures::MetlogFixtures.sampled_timing_event

      # Patch the count and timing methods

      @plugin.instance_eval("@client").stubs(:count).never()
      @plugin.instance_eval("@client").stubs(:timing).with(event.fields['logger'],
                                                           event.fields['fields']['name'],
                                                           event.fields['payload'].to_f,
                                                           event.fields['fields']['rate'].to_f)
      @plugin.receive(event)
  end


  test "malformed events" do
      # This just makes sure that the output plugins don't bomb out on
      # malformed events for statsd
      init_client

      event = LogStash::Fixtures::MetlogFixtures.malformed_statsd_event

      # Patch the count and timing methods

      @plugin.instance_eval("@client").stubs(:count).never()
      @plugin.instance_eval("@client").stubs(:timing).never()
      @plugin.receive(event)
  end


end # TestTagger

