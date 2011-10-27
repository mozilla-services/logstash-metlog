require "logstash/outputs/base"
require "logstash/namespace"
require "thread"
require "net/http"
require "uri"
require "ruby-debug"

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
        puts "[#{self}] We have a logger in http output: [#{@logger}]"
        @httpclient = HttpClient.new(@url_string, @logger)
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
        def initialize(url_string, logger)
            @uri = URI.parse(url_string)
            @queue  = Queue.new
            @logger = logger
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
                        json_payload = JSON(msgs).to_s

                        req = Net::HTTP::Post.new(@uri.path, initheader = {'Content-Type' =>'application/json'})
                        req.body = json_payload
                        response = Net::HTTP.new(@uri.host, @uri.port).start {|http| 
                            http.request(req)
                        }

                        # TODO: what do we do if we get a failure in
                        # log forwarding?
                        puts "Got Bagheera status: [#{response.code}]"

                    else
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
