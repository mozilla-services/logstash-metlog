require "logstash/inputs/base"
require "logstash/namespace"
require "socket"
require "timeout"

# Read events over a UDP socket.
#
# Like stdin and file inputs, each event is assumed to be one line of text.
#
# Can either accept connections from clients or connect to a server,
# depending on `mode`.
class LogStash::Inputs::Udp < LogStash::Inputs::Base

  config_name "udp"

  # When mode is `server`, the address to listen on.
  # When mode is `client`, the address to connect to.
  config :host, :validate => :string, :default => "0.0.0.0"

  # When mode is `server`, the port to listen on.
  # When mode is `client`, the port to connect to.
  config :port, :validate => :number, :required => true

  # Mode to operate in. `server` listens for client connections,
  # `client` connects to a server.
  config :mode, :validate => ["server", "client"], :default => "server"

  public
  def register
    if server?
      @logger.info("Starting udp input listener on #{@host}:#{@port}")
      @server_socket = UDPSocket.new
      
      # Just hardcode the port to make sure things are working the way
      # I expect them to
      # @server_socket.bind(@host, @port)
      @server_socket.bind(nil, 1234)

      # set the max message size to 32k for now
      @max_msg = 32000
    end
  end # def register

  private
  def handle_socket(socket, output_queue, event_source)
    begin
      loop do
        buf = nil
        buf = socket.recvfrom(@max_msg)
        e = self.to_event(buf, event_source)
        if e
          output_queue << e
        end
      end # loop do
    rescue => e
      @logger.debug(["Closing connection with #{socket}", $!])
      @logger.debug(["Backtrace", e.backtrace])
    rescue Timeout::Error
      @logger.debug("Closing connection with #{socket} after read timeout")
    end # begin

  end

  private
  def server?
    @mode == "server"
  end # def server?

  public
  def run(output_queue)
    if server?
      loop do
        # We don't need a new thread for each connection, just read
        # the packets
        s = @server_socket
        @logger.debug("Accepted connection from #{s} on #{@host}:#{@port}")
        # Do nothing for now for the input data
        handle_socket(s, output_queue, "udp://server.blah.blah")
      end # loop
    else
      # this is the client block
      loop do
        client_socket = UDPSocket.new(@host, @port)
        @logger.debug("Opened connection to #{client_socket}")
        handle_socket(client_socket, output_queue, "udp://client.blah.blah")
      end # loop
    end
  end # def run
end # class LogStash::Inputs::Udp


