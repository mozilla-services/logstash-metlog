require "logstash/outputs/base"
require "logstash/namespace"

# Note that the statsd client is imported in the register call so that
# logstash as a whole doesn't have a dependency on the statsd client

# Based on the stock statsd client in logstash

require 'logstash/outputs/cef_syslog'

class LogStash::Outputs::MetlogCef < LogStash::Outputs::Base
  config_name "metlog_cef"
  plugin_status "beta"

  # Only handle events with all of these tags
  # Optional.
  config :tags, :validate => :array, :default => []

  public
  def initialize(params)
    super
    @client = LogStash::Outputs::SyslogSender.new()
  end 

  public 
  def register
  end

  public
  def receive(event)
    return unless output?(event)

    begin
        cef_meta = event.fields['fields']['cef']
        config = {'syslog_options' => cef_meta['syslog_options'],
            'syslog_facility' => cef_meta['syslog_facility'],
            'syslog_ident' => cef_meta['syslog_ident'],
            'syslog_priority' => cef_meta['syslog_priority'],}
        @client.log_msg(event.fields['payload'], config)
    rescue => e
        @logger.warn(["CEF event can't be marshalled for syslog", $!])
        @logger.debug(["backtrace", e.backtrace])
    end
  end # def receive
end # class LogStash::Outputs::MetlogCef
