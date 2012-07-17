require "logstash/inputs/base"
require "logstash/namespace"
require "timeout"

# Read events over a 0MQ SUB socket.
#
# You need to have the 0mq 2.1.x library installed to be able to use
# this input plugin.
#
# The default settings will create a subscriber binding to tcp://127.0.0.1:2120 
# waiting for connecting publishers.
#
class LogStash::Inputs::SafeZeroMQ < LogStash::Inputs::Base

  config_name "safe_zeromq"
  plugin_status "experimental"

  # 0mq socket address to connect or bind to
  config :address, :validate => :string, :default => "tcp://127.0.0.1:2120"

  # 0mq queue size
  config :queue_size, :validate => :number, :default => 20

  # 0mq topic (Used with ZMQ_SUBSCRIBE, see http://api.zeromq.org/2-1:zmq-setsockopt 
  # for 'ZMQ_SUBSCRIBE: Establish message filter')
  config :queue, :validate => :string, :default => "" # default all

  # wether to bind ("server") or connect ("client") to the socket
  config :mode, :validate => [ "server", "client"], :default => "client"

  @source = "0mq_#{@address}/#{@queue}"

  public
  def register
    require "ffi-rzmq"
    require "logstash/util/safe_zmq"
    self.class.send(:include, LogStash::Util::SafeZeroMQ)
    @subscriber = context.socket(ZMQ::PULL)
    error_check(@subscriber.setsockopt(ZMQ::HWM, @queue_size),
                "while setting ZMQ:HWM == #{@queue_size.inspect}")
    error_check(@subscriber.setsockopt(ZMQ::LINGER, 0),
                "while setting ZMQ::LINGER == 0)")
    setup(@subscriber, @address)

    @plugin_state = :registered
  end # def register

  # This method is called when someone or something wants this plugin to shut
  # down. When you successfully shutdown, you must call 'finished'
  # You must also call 'super' in any subclasses.
  public
  def shutdown(queue)
    # We overload the shutdown method for the 0mq input plugin so that
    # the main run loop
    #
    @logger.info("Received shutdown signal", :plugin => self)
    @logger.info("safe_0mq plugin state", :plugin_state => @plugin_state)

    @shutdown_queue = queue

    # TODO: @plugin_state is an instance variable.  It can be set from
    # logstash.agent invoking the shutdown method, which means
    # external threads access this worker's internal state.  Access to
    # all instance variables needs to be guarded with synchronization
    # in order to make sure we don't get volatile memory issues

    if @plugin_state == :finished
      finished
    else
      @plugin_state = :terminating
    end

    @logger.info("safe_0mq setting after shutdown plugin state", :plugin_state => @plugin_state)
    @logger.info("safe_0mq shutdown method completed")
  end # def shutdown

  def thread_teardown
      @logger.info("safe_0mq: tearing down 0mq parts")
      begin
          @subscriber.close
          # This seems to sleep past the end of process
          sleep 1 # This is stupid.  It's a race condition waiting to happen.
                  # 0mq's close operation is an async process
      rescue => e
          @logger.error("safe_0mq: Error while closing subscriber", :error => e)
      end
      @logger.info("safe_0mq: Success shutting down 0mq subscriber socket")
  end # def teardown

  def server?
    @mode == "server"
  end # def server?

  def run(output_queue)
    begin
      @plugin_state = :running

      @logger.info("safe_0mq run loop starting")

      loop do
        msg = ''
        # We want to do a non-blocking recv or else we won't be able
        # to recognize when
        rc = @subscriber.recv_string(msg,  ZMQ::NOBLOCK)
        if msg.length > 0 
            @logger.info("0mq: receiving", :event => msg)
            e = self.to_event(msg, @source)
            if e
              output_queue << e
            end
        else
            # No messages, just sleep for 10 ms so we don't chew cycles
            # needlessly
            sleep(0.001)
        end

        if @plugin_state == :terminating
            @logger.info("safe_0mq: runloop plugin_state", :plugin_state => @plugin_state)
            break
        end
      end
      thread_teardown
      @logger.info("safe_0mq: run loop is complete")
    rescue => e
      @logger.debug("ZMQ Error", :subscriber => @subscriber,
                    :exception => e, :backtrace => e.backtrace)
    rescue Timeout::Error
      @logger.debug("Read timeout", subscriber => @subscriber)
    end # begin
  end # def run
end # class LogStash::Inputs::ZeroMQ
