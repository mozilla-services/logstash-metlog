require "rubygems"
require "logstash/loadlibs"
require "logstash"
require "logstash/filters"
require "logstash/filters/tagger"
require "logstash/inputs/zeromq"
require "logstash/event"
require "json"
require "logstash/fixtures/metlog"

# You need to import both the test runner and ruby-debug
require "logstash_test_runner"
require "ruby-debug"

describe LogStash::Filters::Tagger do
  before do
    @typename = "metlog"

    # This is just a toy JSON blob. 
    #
    # TODO: This will probably break when the envelope and payload in
    # the zeromq code gets split

    # surely there's a better way to get class variables
    @stack_error = LogStash::Fixtures::MetlogFixtures.class_eval("@@stack_error")

  end

  def config_input(cfg)
        # this method is *not* executed automatically
        # 
        # A bit confused here. When you set the type, the configuration
        # takes in a string, but the testcase expects a list?

        cfg['format'] = ['json']
        cfg["type"] = ["metlog"]

        @input = LogStash::Inputs::Zeromq.new(cfg)
        @input.register
  end # def config

  def config_filter(cfg)
        # this method is *not* executed automatically
        # 
        # A bit confused here. When you set the type, the configuration
        # takes in a string, but the testcase expects a list?

        cfg["type"] = ["metlog"]
        cfg['pattern'] = ['logger', "stacktrace"]
        cfg['add_tag'] = ['metlog_dest_bagheera']

        @filter = LogStash::Filters::Tagger.new(cfg)
        @filter.register
  end # def config

  
  test "send to bagheera" do
      # weird - config {} doesn't seem to work
      config_input ({})
      config_filter ({})

      # This is a bit weird.  The LogStash:Inputs:Base#to_event method
      # is protected, but you can bypass it by using the Object#send
      # method to invoke the event serialization machinery
      event = @input.send :to_event, JSON(@stack_error).to_s, '0mq:mock'

      @filter.filter(event)

      # Check that we've got just the tags that we're expecting
      assert event.tags.include? "metlog_dest_bagheera"
      assert !(event.tags.include?"metlog_dest_sentry")
  end # testing a single match

end # TestTagger
