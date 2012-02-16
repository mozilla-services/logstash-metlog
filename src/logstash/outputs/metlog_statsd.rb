require "logstash/outputs/base"
require "logstash/namespace"

# Note that the statsd client is imported in the register call so that
# logstash as a whole doesn't have a dependency on the statsd client

# Based on the stock statsd client in logstash

require 'logstash/outputs/simple_statsd'

class LogStash::Outputs::MetlogStatsd < LogStash::Outputs::Base
  config_name "metlog_statsd"
  plugin_status "beta"

  # The address of the Statsd server.
  config :host, :validate => :string, :default => "localhost"

  # The port to connect to on your statsd server.
  config :port, :validate => :number, :default => 8125

  # Only handle events with all of these tags
  # Optional.
  config :tags, :validate => :array, :default => []

  public
  def initialize(params)
    super
    @client = LogStash::Outputs::SimpleStatsd.new(@host, @port)
  end 

  public 
  def register
  end

  public
  def receive(event)
    return unless output?(event)

    begin
        ns = event.fields['fields']['logger']
        key = event.fields['fields']['name']
        value = event.fields['payload'].to_f
        rate = event.fields['fields']['rate'].to_f
    rescue => e
        @logger.warn(["Event can't be marshalled for statsd", @host, @port, $!])
        @logger.debug(["backtrace", e.backtrace])
    end

    if 'counter' == event.fields['type']
        @client.count(ns, key, value, rate)
    elsif 'timer' == event.fields['type']
        @client.timing(ns, key, value, rate)
    else
        @logger.warn("Unexpected event passed into metlog_statsd. Event => #{event}")
    end
  end # def receive
end # class LogStash::Outputs::MetlogStatsd

