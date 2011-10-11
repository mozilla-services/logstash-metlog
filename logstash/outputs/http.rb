require "logstash/outputs/base"
require "logstash/namespace"
require "thread"


# Write events over an HTTP connection
# Basically, this just queues up messages and then forwards off
# batches of messages to a receiver.
#
# Each event json is separated by a newline.
#
# Can only act as a client that sends messages to a receiver.

class LogStash::Outputs::Http < LogStash::Outputs::Base

    config_name "http"

    # When mode is `client`, the address to connect to.
    config :host, :validate => :string, :required => true

    # When mode is `client`, the port to connect to.
    config :port, :validate => :number, :required => true

    class Client
        public
        def initialize(socket, logger)
            @socket = socket
            @logger = logger
            @queue  = Queue.new
        end

        public
        def run
            loop do
                begin
                    # TODO: rewrite this to bach up messages from the
                    # queue and reconstitute a 'large' JSON message to
                    # POST up
                    @socket.write(@queue.pop)
                rescue => e
                    @logger.warn(["http output exception", @socket, $!])
                    @logger.debug(["backtrace", e.backtrace])
                    break
                end
            end
        end # def run

        public
        def write(msg)
            @queue.push(msg)
        end # def write
    end # class Client

    public
    def register
        @client_socket = nil
    end # def register

    private
    def connect
        @client_socket = udpSocket.new(@host, @port)
    end # def connect

    public
    def receive(event)
        wire_event = event.to_hash.to_json + "\n"

        begin
            connect unless @client_socket
            @client_socket.write(event.to_hash.to_json)
            @client_socket.write("\n")
        rescue => e
            @logger.warn(["udp output exception", @host, @port, $!])
            @logger.debug(["backtrace", e.backtrace])
            @client_socket = nil
        end
    end # def receive
end # class LogStash::Outputs::Udp
