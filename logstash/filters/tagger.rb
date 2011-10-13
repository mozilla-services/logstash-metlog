# This filter decodes JSON blobs and matches on 
# simple key/value pairs.  
#
# Basic usage in your logstash configuration
#
#
#
#


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

    # Specify a pattern to parse with. This will match the JSON blob.
    # For patterns will match only with exact matches.  These are not
    # regular expressions.
    config :pattern, :validate => :hash, :default => {}

    public
    def register
        # Don't think we need to do anything special here
        puts "tagger is enabled"
    end # def register

    public
    def filter(event)
        # filter_matched(event)


        ts = event[:timestamp]

        puts "Parsed Fields: #{event.fields}"
    end # def filter

end # class LogStash::Filters::Tagger
