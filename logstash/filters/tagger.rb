# Call this file 'foo.rb' (in logstash/filters, as above)
require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::Tagger < LogStash::Filters::Base
    # Setting the cfig_name here is required. This is how you
    # cfigure this filter from your logstash cfig.
    #
    # filter {
    #   foo { ... }
    # }
    config_name "tagger"

    # Replace the message with this value.
    config :match, :validate => :hash, :default => {}

    public
    def register
        # TODO: reconstruct the array into something that will tag
        # things out faster
        puts "Tagger filter is setup!"
    end # def register

    public
    def filter(event)
        # TODO: run through the array of tags to do matches and add
        # the tag key if a match is found
        puts "Filtering message: #{event}"
    end # def filter

end # class LogStash::Filters::Foo
