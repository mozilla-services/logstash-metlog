require "logstash/outputs/base"
require "logstash/namespace"
require "thread"
require "logstash/outputs/sentry"

# Write events over an HTTP connection
# Basically, this just queues up messages and then forwards off
# batches of messages to a receiver.
#
# Each event json is separated by a newline.
#
# Can only act as a client that sends messages to a receiver.

class LogStash::Outputs::MetlogSentry < LogStash::Outputs::Base

    config_name "metlog_sentry"
    plugin_status "beta"

    # Only handle events with all of these tags
    # Optional.
    config :tags, :validate => :array, :default => []

    # The DSN of the sentry server
    config :dsn, :validate => :string, :required => true

    public
    def register
        @sentry_holder = SentryHolder.new(@dsn)
        @push_thread = Thread.new(@sentry_holder) do |client|
            client.run
        end
    end # def register

    public
    def receive(event)
        return unless output?(event)
        @sentry_holder.enqueue(event)
    end # def receive


    class SentryHolder
        public
        def initialize(dsn)
            @dsn = dsn
            @sentry = SentryServer.new(dsn)
            @queue  = Queue.new
        end

        public
        def run
            while true
                event = @queue.pop
                @sentry.send(event['payload'], event['fields']['epoch_timestamp'])
            end
        end # def run

        public
        def enqueue(event)
            @queue.push(event)
        end # def enqueue 

    end # class SentryHolder

end # class LogStash::Outputs::MetlogSentry
