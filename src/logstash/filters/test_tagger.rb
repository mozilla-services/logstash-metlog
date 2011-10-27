require "logstash"

# You need to import both the test runner and ruby-debug
require "logstash_test_runner"
require "ruby-debug"

# Plugin under test
require "logstash/filters/tagger"

# Fixture data
require "logstash/fixtures/metlog"

describe LogStash::Filters::Tagger do
  before do
    @typename = "metlog"
  end

  def config_filter
        # this method is *not* executed automatically
        # 
        # A bit confused here. When you set the type, the configuration
        # takes in a string, but the testcase expects a list?

        cfg = {}
        cfg["type"] = ["metlog"]
        cfg['pattern'] = ['logger', "stacktrace"]
        cfg['add_tag'] = ['metlog_dest_bagheera']

        @filter = LogStash::Filters::Tagger.new(cfg)
        @filter.register
  end # def config

  test "send to bagheera" do
      # weird - config {} doesn't seem to work
      config_filter

      # This is a bit weird.  The LogStash:Inputs:Base#to_event method
      # is protected, but you can bypass it by using the Object#send
      # method to invoke the event serialization machinery
      event = LogStash::Fixtures::MetlogFixtures.stackerror_event

      @filter.filter(event)

      # Check that we've got just the tags that we're expecting
      assert event.tags.include? "metlog_dest_bagheera"
      assert !(event.tags.include?"metlog_dest_sentry")
  end # testing a single match

end # TestTagger
