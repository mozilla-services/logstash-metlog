require "logstash/inputs/base"
require "logstash/namespace"
require "timeout"

# Respond to handshaking messages over 0mq using a REQ/REPL socket
#
# You need to have the 0mq 2.1.x library installed to be able to use
# this input plugin.
#
# The default settings will create a subscriber binding to tcp://127.0.0.1:2120 
# waiting for connecting publishers.
#
class LogStash::Inputs::ZeroMQHandshake < LogStash::Inputs::Base

  config_name "zeromq_handshake"
  plugin_status "experimental"

  # 0mq socket address to connect or bind to
  config :address, :validate => :string, :default => "tcp://127.0.0.1:2121"

  # wether to bind ("server") or connect ("client") to the socket
  config :mode, :validate => [ "server", "client"], :default => "client"

  @source = "0mq_#{@address}/#{@queue}"

  public
  def register
    require "ffi-rzmq"
    require "logstash/util/zeromq"
    self.class.send(:include, LogStash::Util::ZeroMQ)

    @socket = context.socket(ZMQ::REP)
    error_check(@socket.setsockopt(ZMQ::LINGER, 1),
                "while setting ZMQ::LINGER == 1)")
    setup(@socket, @address)
  end # def register

  def teardown
    error_check(@socket.close, "while closing the zmq socket")
  end # def teardown

  def server?
    @mode == "server"
  end # def server?

  def run(output_queue)
    begin
      loop do
        # do a ping/pong
        @socket.recv_string()
        @socket.send('')
      end
    rescue => e
      @logger.debug("ZMQ Error", :socket => @socket,
                    :exception => e, :backtrace => e.backtrace)
    rescue Timeout::Error
      @logger.debug("Read timeout", subscriber => @subscriber)
    end # begin
  end # def run
end # class LogStash::Inputs::ZeroMQ
