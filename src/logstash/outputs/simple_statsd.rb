require 'logstash'
require 'socket'

# = SimpleStatsd: A Statsd client  
#
#   based heavily on : (https://github.com/etsy/statsd)
#
#   This statsd client has mainly been modified to act as a central
#   statsd client for multiple applications.
#
#   This client implements only the basic statsd functions calls 
#   with no special shortcuts.
#  
#   The only instance methods you should ever need are #count and
#   #timing.  See the test case for usage.

class LogStash::Outputs::SimpleStatsd
    #characters that will be replaced with _ in stat names
    RESERVED_CHARS_REGEX = /[\:\|\@]/

    # @param [String] host your statsd host
    # @param [Integer] port your statsd port
    def initialize(host, port=8125)
        @host, @port = host, port
    end

    # Sends an arbitrary count for the given stat to the statsd server.
    #
    # @param [String] stat stat name
    # @param [Integer] count count
    # @param [Integer] sample_rate sample rate, 1 for always
    public
    def count(ns, stat, count, sample_rate=1)
        send(ns, stat, count, 'c', sample_rate)
    end

    # Sends a timing (in ms) for the given stat to the statsd server. The
    # sample_rate determines what percentage of the time this report is sent. The
    # statsd server then uses the sample_rate to correctly track the average
    # timing for the stat.
    #
    # @param stat stat name
    # @param [Integer] ms timing in milliseconds
    # @param [Integer] sample_rate sample rate, 1 for always
    public
    def timing(ns, stat, ms, sample_rate=1)
        send(ns, stat, ms, 'ms', sample_rate)
    end

    def send(namespace, stat, delta, type, sample_rate)
        prefix = "#{namespace}." unless namespace == ''
        stat = stat.to_s.gsub('::', '.').gsub(RESERVED_CHARS_REGEX, '_')
        send_to_socket("#{prefix}#{stat}:#{delta}|#{type}#{'|@' << sample_rate.to_s if sample_rate < 1}")
    end

    def send_to_socket(message)
        socket.send(message, 0, @host, @port)
    end

    def socket
        @socket ||= UDPSocket.new
    end
end
