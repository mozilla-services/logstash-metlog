# This filter monitors events that have one or more tags provided to
# this filter.  If no tags match, then the message is tagged as 'filter-tagall'
# for routing to a default output plugin

require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::Catchall < LogStash::Filters::Base

    config_name "catchall"
    plugin_status "beta"


    # Specify a pattern to parse with. This will match the JSON blob.
    # For patterns will match only with exact matches.  These are not
    # regular expressions.
    config :tags, :validate => :array, :default => []

    public
    def register
        # Don't think we need to do anything special here
    end # def register

    public
    def filter(event)
        return unless filter?(event)

        matched_tags = @tags & event.tags
        if matched_tags.empty?
            event.tags.append('filter-catchall')
        end
    end # def filter

end # class LogStash::Filters::Tagger
