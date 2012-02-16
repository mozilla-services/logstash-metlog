require "logstash/namespace"
require "logstash/outputs/base"
require "logstash/util/signals"

# File output.
#
# Write events as one line JSON records to disk
#
class LogStash::Outputs::MetlogFile < LogStash::Outputs::Base

  config_name "metlog_file"
  plugin_status "beta"

  # Only handle events with all of these tags
  # Optional.
  config :tags, :validate => :array, :default => []

  # The path to the file to write. Event fields can be used here,
  # like "/var/log/logstash/%{@source_host}/%{application}"
  config :path, :validate => :string, :required => true

  # The format of output data (json, preformatted_field)
  config :format, :validate => :string, :required => true, :default => "json"

  # If the output type is 'preformatted_field', we only extract the
  config :formatted_field, :validate => :string, :default => ""

  public
  def register
      require "fileutils" # For mkdir_p

      @fileclient = FileClient.new(@path, @logger, @format, @formatted_field)
      @push_thread = Thread.new(@fileclient) do |client|
          client.run
      end
  end # def register

    public
    def receive(event)
        return unless output?(event)

        @fileclient.enqueue(event)
    end # def receive


    ############
    ############
    ############
    ############
    #
    #
    #
    # We need a separate thread to append to a log file or else we
    # will block as events come in.
    # Only flush the bufffers when we have idle time
    class FileClient
        public
        def initialize(path, logger, format, formatted_field)
            @path = path
            @queue  = Queue.new
            @logger = logger

            @format = format
            @formatted_field = formatted_field

            @logfile = open(path)

            # Hook SIGHUP (1) to this instance
            LogStash::Util::Signals::LibC.signal(1) do |signal|
                if signal == 1
                    @logfile.flush
                    @logfile.close

                    @logfile = open(path)
                    @logfile.flush
                end
            end
        end 

        public
        def run
            loop do
                begin
                    # append to disk as they come in
                    event = @queue.pop

                    case @format
                    when "json"
                        data_hash = event.to_hash
                        # Replace all keys that start with '@' with
                        # 'LS_' to create a namespace for logstash
                        # messages

                        new_map = {}
                        data_hash.each do |k, v|
                            if k.start_with? '@'
                                new_map["LS_" + k[1..-1]] = v
                            else
                                new_map[k] = v
                            end
                        end
                        @logfile.puts(new_map.to_json())
                    when "preformatted_field"
                        txt = event['fields'][@formatted_field]
                        if txt
                            @logfile.puts(txt)
                        end
                    end

                    # This is probably a bad idea to flush all the
                    # time.  Not quite sure what JRuby does, if it
                    # does anything with I/O buffers
                    @logfile.flush

                rescue => e
                    @logger.debug(["backtrace", e.backtrace])
                    break
                end
            end
        end # def run

        private
        def open(path)
            if File.directory?(path)
                raise ArgumentError, "Plugin expects a path to a file, not a directory."
            end

            @logger.info("Opening file", :path => path)

            dir = File.dirname(path)
            if !Dir.exists?(dir)
                @logger.info("Creating directory", :directory => dir)
                FileUtils.mkdir_p(dir)
            end

            return File.new(path, "a")
        end

        public
        def enqueue(msg)
            @queue.push(msg)
        end # def enqueue 

    end # class Client

end # class LogStash::Outputs::MetlogFile
