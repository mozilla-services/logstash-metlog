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
    plugin_status "beta"


    # Specify a pattern to parse with. This will match the JSON blob.
    # For patterns will match only with exact matches.  These are not
    # regular expressions.
    config :pattern, :validate => :hash, :default => {}

    public
    def register
        # Don't think we need to do anything special here
    end # def register

    public
    def filter(event)
        return unless filter?(event)

        @pattern.each_pair{ |keypath, match_pattern|
            obj = event.fields
            keypath.split('/').each{ |segment|
                if (obj == nil)
                    # Oops - we ran off the end of the keypath
                    # skip to the next keypath
                    next
                end
                obj = obj[segment]
            }

            if match_pattern == '*' or obj.to_s == match_pattern
                filter_matched(event)
                break
            end
        }
    end # def filter

end # class LogStash::Filters::Tagger
