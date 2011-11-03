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
      @subscriber.bind(@zeromq_bind)

      @source = "0mq:#{@zeromq_bind}"
    end
  end # def register

  private
  def server?
    @mode == "server"
  end # def server?

  protected
  def to_event(env, payload, source)
    event = LogStash::Event.new
    event.type = @type
    event.tags = @tags.clone rescue []
    event.source = source

    begin
      fields = JSON.parse(env)
      fields.each { |k, v| event[k] = v }
    rescue => e
      @logger.warn("Trouble parsing json input", :input => env,
                   :source => source, :exception => e,
                   :backtrace => e.backtrace)
      return nil
    end # begin
    event["payload"] = payload
    return event
  end # def to_event

  public
  def dequeue_message(output_queue)
    # Dequeue a single message.  Makes for easier testing
    @logger.debug("Accepted connection from #{@subscriber} on #{@host}:#{@port}")

    begin
      env = @subscriber.recv_string
      if @subscriber.more_parts?
        payload = @subscriber.recv_string
      else
        payload = ""
      end
      e = self.to_event(env, payload, @source)
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


