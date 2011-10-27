# You'll need to import logstash for all tests to get all the logstash
# namespaces. This should always be first
require "logstash"

# You need to import both the test runner and ruby-debug
# You need these two for all test cases
require "logstash_test_runner"
require "ruby-debug"
require 'mocha'

# The plugin under test
require "logstash/outputs/simple_statsd"

describe LogStash::Outputs::SimpleStatsd do

  def init_client
      # setup a dummy client
      @client = LogStash::Outputs::SimpleStatsd.new('localhost')
  end

  test "simple increment" do
      # This test just makes sure that the input plugin will decode
      # JSON text blobs into event objects

      init_client
      expected_result = 'grok:3|c'
      @client.stubs(:send_to_socket).with(expected_result)
      @client.count('', 'grok', 3)
  end

  test "expected failure for an increment" do
      init_client
      # This should *not* match
      expected_result = 'grok:1|c'
      @client.stubs(:send_to_socket).with(Not(equals(expected_result)))
      @client.count('not a matching ns', 'grok', 3)
  end

  test "namespaced increment" do
      init_client
      expected_result = 'myns.grok:23|c'

      @client.stubs(:send_to_socket).with(equals(expected_result))
      @client.count('myns', 'grok', 23)
  end 

  test "sampled increment @ 10%" do
      init_client
      expected_result = 'myns.grok:23|c|@0.1'
      @client.stubs(:send_to_socket).with(equals(expected_result))
      @client.count('myns', 'grok', 23, 0.1)
  end

  test "sampled decrement @ 15%" do
      init_client
      expected_result = 'myns.grok:-1|c|@0.15'
      @client.stubs(:send_to_socket).with(equals(expected_result))
      @client.count('myns', 'grok', -1, 0.15)
  end

  test "timing an event" do
      init_client
      expected_result = 'grok:320|ms'
      @client.stubs(:send_to_socket).with(equals(expected_result))
      @client.timing('', 'grok', 320)
  end

  test "timing an event @ 18%" do
      init_client
      expected_result = 'grok:320|ms|@0.18'
      @client.stubs(:send_to_socket).with(equals(expected_result))
      @client.timing('', 'grok', 320, 0.18)
  end

end # TestTagger

