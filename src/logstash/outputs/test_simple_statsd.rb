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

  test "test send incr" do
      # This test just makes sure that the input plugin will decode
      # JSON text blobs into event objects

      init_client
      expected_result = 'grok:3|c'
      @client.stubs(:send_to_socket).with(expected_result)
      @client.count('', 'grok', 3)

      init_client
      # This should *not* match
      @client.stubs(:send_to_socket).with(Not(equals(expected_result)))
      @client.count('not a matching ns', 'grok', 3)

      init_client
      # This should match
      expected_result = 'myns.grok:23|c'
      @client.stubs(:send_to_socket).with(equals(expected_result))
      @client.count('myns', 'grok', 23)

  end # testing a single match

end # TestTagger

