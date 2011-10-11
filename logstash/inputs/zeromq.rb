require "logstash/inputs/base"
require "logstash/namespace"
require 'ffi-rzmq'
require "timeout"

# Read events over a ZeroMQ socket.
#
# Like stdin and file inputs, each event is assumed to be one line of text.
#
# Can either accept connections from clients or connect to a server,
# depending on `mode`.
class LogStash::Inputs::Zeromq < LogStash::Inputs::Base

  config_name "zeromq"

  config :protocol, :validate => :string, :default => "tcp"

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
      @logger.info("Starting ZeroMQ input listener on #{@host}:#{@port}")
      # TODO: where to we put destructor code for the context and the
      # subscriber?

      @context = ZMQ::Context.new
      @subscriber = @context.socket(ZMQ::SUB)
      @subscriber.setsockopt(ZMQ::IDENTITY, "MozillaMetrics")
      @subscriber.setsockopt(ZMQ::SUBSCRIBE, "")

      url = "#{@protocol}://#{@host}:#{@port}"
      puts "Using : #{url}"
      @subscriber.connect(url)

    end
  end # def register

  private
  def handle_socket(socket, output_queue, event_source)
    begin
      loop do
        buf = @subscriber.recv_string
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
        # the messages as they come in
        s = @server_socket
        @logger.debug("Accepted connection from #{s} on #{@host}:#{@port}")
        # Do nothing for now for the input data
        handle_socket(s, output_queue, "0mq://#{@host}:#{@port}")
      end # loop
    else
      # this is the client block
      raise ArgumentError, "Client input filter isn't supported"
    end
  end # def run
end # class LogStash::Inputs::Udp


