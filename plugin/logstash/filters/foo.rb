# Call this file 'foo.rb' (in logstash/filters, as above)
require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::Foo < LogStash::Filters::Base
    # Setting the cfig_name here is required. This is how you
    # cfigure this filter from your logstash cfig.
    #
    # filter {
    #   foo { ... }
    # }
    config_name "foo"

    # Replace the message with this value.
    config :message, :validate => :string

    public
    def register
        # nothing to do
    end # def register

    public
    def filter(event)
        if @message
            # Replace the event message with our message as cfigured in the
            # config file.
            # If no message is specified, do nothing.
            event.message = "New message: [#{@message}] [#{event.message}]"
        end
    end # def filter
end # class LogStash::Filters::Foo
