require "logstash/outputs/base"
require "logstash/namespace"
require "thread"
require "net/http"
require "uri"


# Write events over an HTTP connection
# Basically, this just queues up messages and then forwards off
# batches of messages to a receiver.
#
# Each event json is separated by a newline.
#
# Can only act as a client that sends messages to a receiver.

class LogStash::Outputs::Http < LogStash::Outputs::Base

    config_name "http"

    config :match_tag, :validate => :string, :required => true

    # The URL we're gonna POST to 
    config :url_string, :validate => :string, :required => true

    public
    def register
        @httpclient = HttpClient.new(@url_string)
        @push_thread = Thread.new(@httpclient) do |client|
            client.run
        end
    end # def register

    public
    def receive(event)
        begin
            # We only want to queue up events that match the tag we're
            # looking for, otherwise - someone else can handle it
            if event.tags.include? @match_tag
                wire_event = event.to_hash
                @httpclient.enqueue(wire_event)
            end
        rescue => e
            @logger.warn(["http output exception", @host, @port, $!])
            @logger.debug(["backtrace", e.backtrace])
            @httpclient = nil
        end
    end # def receive


    ############
    ############
    ############
    ############
    #
    #
    #
    class HttpClient
        public
        def initialize(url_string)
            @uri = URI.parse(url_string)
            @queue  = Queue.new
        end

        public
        def run
            loop do
                begin
                    # batch up messages from the queue and
                    # reconstitute a 'large' JSON message to POST up
                    msgs = []
                    while @queue.length > 0 and msgs.length < 100
                        msgs << @queue.pop
                    end

                    if msgs.length > 0
                        response = Net::HTTP.post_form(@uri, {"data" => JSON(msgs).to_s})
                    else
                        # TODO: is there a better way to do this?
                        sleep 1
                    end
                rescue => e
                    @logger.warn(["http output exception", @socket, $!])
                    @logger.debug(["backtrace", e.backtrace])
                    break
                end
            end
        end # def run

        public
        def enqueue(msg)
            @queue.push(msg)
        end # def enqueue 
    end # class Client


end # class LogStash::Outputs::Udp
