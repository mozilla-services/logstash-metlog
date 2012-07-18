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
  plugin_status "experimental"

  # When mode is `server`, the address to listen on.
  # When mode is `client`, the address to connect to.
  config :host, :validate => :string, :default => "0.0.0.0"

  # When mode is `server`, the port to listen on.
  # When mode is `client`, the port to connect to.
  config :port, :validate => :number, :required => true

  # Mode to operate in. `server` listens for client connections,
  # `client` connects to a server.
  config :mode, :validate => ["server", "client"], :default => "server"

  @source = "udp://#{@host}:#{@port}"

  public
  def register
      @logger.info("Starting udp input listener on #{@host}:#{@port}")
      @server_socket = UDPSocket.new
      @server_socket.bind(@host, @port)
  end # def register

  private
  def server?
    @mode == "server"
  end # def server?

  public
  def run(output_queue)
    if server?
        loop do
            begin
                buf = nil
		buf = @server_socket.recvfrom(60000)[0].chomp
                @logger.info("Got buffer")
                e = self.to_event(buf, @source)
                if e
                    output_queue << e
                end
            rescue => e
                @logger.warn(["Error while receving data : #{@server_socket}", $!])
                @logger.warn(["Backtrace", e.backtrace])
            rescue Timeout::Error
                @logger.warn("Closing connection with #{@server_socket} after read timeout")
            end # begin
        end # loop do
    end
  end # def run
end # class LogStash::Inputs::Udp


