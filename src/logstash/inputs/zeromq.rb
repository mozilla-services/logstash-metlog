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

  config :zeromq_bind, :validate => :string, :default => "tcp://127.0.0.1:5565"

  # Mode to operate in. `server` listens for client connections,
  # `client` connects to a server.
  config :mode, :validate => ["server", "client"], :default => "server"

  config :queue_length, :validate => :number, :default => 1000

  # We can only have 1 context per process.
  # TODO: What does JRuby do w.r.t class loaders and threads?
  @@context = ZMQ::Context.new

  public
  def initialize(params)
    super
    @subscriber = @@context.socket(ZMQ::SUB)
  end # def initialize

  public
  def register
    if server?
      @logger.info("Starting ZeroMQ input listener on #{@host}:#{@port}")

      # we need to set a hard cap to messages or else we run out of
      # memory
      @subscriber.setsockopt(ZMQ::HWM, @queue_length)

      # Subscribe to all messages
      @subscriber.setsockopt(ZMQ::SUBSCRIBE, "")
      @subscriber.connect(@zeromq_bind)

      @source = "0mq:#{@zeromq_bind}"
    end
  end # def register


  private
  def server?
    @mode == "server"
  end # def server?

  public
  def dequeue_message(output_queue)
      # Dequeue a single message.  Makes for easier testing
      @logger.debug("Accepted connection from #{@subscriber} on #{@host}:#{@port}")

      begin
          buf = @subscriber.recv_string
          e = self.to_event(buf, @source)
          if e
              output_queue << e
          end
      rescue => e
          @logger.debug(["Closing connection with #{@subscriber}", $!])
          @logger.debug(["Backtrace", e.backtrace])
      rescue Timeout::Error
          @logger.debug("Closing connection with #{@subscriber} after read timeout")
      end # begin

  end

  public
  def run(output_queue)
    if server?
      loop do
        # We don't need a new thread for each connection, just read
        # the messages as they come in
        dequeue_message(output_queue)
      end # loop
    else
      # this is the client block
      raise ArgumentError, "Client input filter isn't supported"
    end
  end # def run
end # class LogStash::Inputs::Zeromq


