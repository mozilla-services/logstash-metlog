#!/usr/bin/env ruby

require 'syslog'
require 'thread'

class LogStash::Outputs::SyslogSender

    @@semaphore = Mutex.new
    @@log_opened = nil

    @@SYSLOG_OPTIONS = {'PID' => Syslog::LOG_PID,
                       'CONS' => Syslog::LOG_CONS,
                       'NDELAY' => Syslog::LOG_NDELAY,
                       'NOWAIT'=>  Syslog::LOG_NOWAIT}

    @@SYSLOG_PRIORITY = {'EMERG' => Syslog::LOG_EMERG,
                        'ALERT' => Syslog::LOG_ALERT,
                        'CRIT' => Syslog::LOG_CRIT,
                        'ERR' => Syslog::LOG_ERR,
                        'WARNING' => Syslog::LOG_WARNING,
                        'NOTICE' => Syslog::LOG_NOTICE,
                        'INFO' => Syslog::LOG_INFO,
                        'DEBUG' => Syslog::LOG_DEBUG}

    @@SYSLOG_FACILITY = {'KERN' => Syslog::LOG_KERN,
                        'USER' => Syslog::LOG_USER,
                        'MAIL' => Syslog::LOG_MAIL,
                        'DAEMON' => Syslog::LOG_DAEMON,
                        'AUTH' => Syslog::LOG_AUTH,
                        'LPR' => Syslog::LOG_LPR,
                        'NEWS' => Syslog::LOG_NEWS,
                        'UUCP' => Syslog::LOG_UUCP,
                        'CRON' => Syslog::LOG_CRON,
                        'LOCAL0' => Syslog::LOG_LOCAL0,
                        'LOCAL1' => Syslog::LOG_LOCAL1,
                        'LOCAL2' => Syslog::LOG_LOCAL2,
                        'LOCAL3' => Syslog::LOG_LOCAL3,
                        'LOCAL4' => Syslog::LOG_LOCAL4,
                        'LOCAL5' => Syslog::LOG_LOCAL5,
                        'LOCAL6' => Syslog::LOG_LOCAL6,
                        'LOCAL7' => Syslog::LOG_LOCAL7}



    public
    def log_msg(msg, config)
        @@semaphore.synchronize {
            ident = config['syslog_ident']
            logopt = _str2logopt(config['syslog_options'])
            facility = _str2facility(config['syslog_facility'])
            if @@log_opened != [ident, logopt, facility]
                @@log_opened = [ident, logopt, facility]
                Syslog.open(ident, logopt, facility)
            end
        }
        priority = _str2priority(config['syslog_priority'])
        Syslog.log(priority, msg)
    end

    def _str2logopt(value)
        res = 0
        if value != nil
            value.split(',').each{|opt|
                res = res | @@SYSLOG_OPTIONS[opt.strip]
            }
        end
        return res
    end

    def _str2priority(value)
        if value == nil
            return Syslog::LOG_INFO
        end
        return @@SYSLOG_PRIORITY[value.strip]
    end


    def _str2facility(value)
        if value == nil
            return Syslog::LOG_LOCAL4
        else
            return @@SYSLOG_FACILITY[value.strip]
        end
    end

    def close
        @@semaphore.synchronize {
            if Syslog.opened?
                Syslog.close()
            end
            @@log_opened = nil
        }
    end
end
