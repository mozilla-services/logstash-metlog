# You'll need to import logstash for all tests to get all the logstash
# namespaces. This should always be first
require "logstash"

# You need to import both the test runner and ruby-debug
# You need these two for all test cases
require "logstash_test_runner"
require "ruby-debug"
require 'mocha'

# Fixture data
require "logstash/fixtures/metlog"

# The plugin under test
require "logstash/inputs/zeromq"
require "logstash/filters/tagger"

require "json"

describe LogStash::Inputs::Zeromq do
  before do
      # Pull a JSON blob from the fixtures
      # TODO: need to convert this into 2 messages for the envelope and
      # payload when we split that codebase
      @json_blob  = JSON(LogStash::Fixtures::MetlogFixtures.class_eval("@@stack_error")).to_s
  end

  def config_input(cfg)
      # this method is *not* executed automatically
      # 
      # A bit confused here. When you set the type, the configuration
      # takes in a string, but the testcase expects a list?

      cfg['format'] = ['json']
      cfg["type"] = ["metlog"]

      @input = LogStash::Inputs::Zeromq.new(cfg)
      # Don't register the input plugin as it just starts the server
      # socket
      #@input.register
  end # def config

  test "test message decode" do
      # This test just makes sure that the input plugin will decode
      # JSON text blobs into event objects
      
      # weird - config {} doesn't seem to work
      config_input({})

      # Patch the 0mq socket in the input plugin and replace the
      # :recv_string method with a stub that sends our fixture JSON blob
      @input.instance_eval("@subscriber").stubs(:recv_string).returns(@json_blob)
                                                             .then.returns('not visible') \
                                                             .then.returns('nor this')
      @input.instance_eval("@subscriber").stubs(:more_parts?).returns(false)

      output_queue = []
      @input.dequeue_message(output_queue)
      event = output_queue.shift

      assert event.fields['timestamp'] == "2011-10-13T09:43:44.386392"
      assert event.fields["metadata"] == {"some_data"=>"foo"}
      assert event.fields["type"] == "error"
      assert event.fields["logger"] == "stacktrace"
      assert event.fields["severity"] == 0
      assert event.fields["message"] == "some log text"
      assert event.fields["payload"] == ""

  end # testing a single match

  test "test multipart decode" do
      # This test just makes sure that the input plugin will decode
      # JSON text blobs into event objects
      
      # weird - config {} doesn't seem to work
      config_input({})

      # Patch the 0mq socket in the input plugin and replace the
      # :recv_string method with a stub that sends our fixture JSON blob
      PAYLOAD = "blah blah"
      @input.instance_eval("@subscriber").stubs(:recv_string).returns(@json_blob) \
                                                             .then.returns(PAYLOAD) \
                                                             .then.returns(nil)

      @input.instance_eval("@subscriber").stubs(:more_parts?).returns(true) \
                                                             .then.returns(false)
      output_queue = []
      @input.dequeue_message(output_queue)
      event = output_queue.shift

      # Check that we've got a payload
      assert event.fields['timestamp'] == "2011-10-13T09:43:44.386392"
      assert event.fields["metadata"] == {"some_data"=>"foo"}
      assert event.fields["type"] == "error"
      assert event.fields["logger"] == "stacktrace"
      assert event.fields["severity"] == 0
      assert event.fields["message"] == "some log text"
      assert event.fields["payload"] == PAYLOAD
      
  end # testing a single match

end # TestTagger

