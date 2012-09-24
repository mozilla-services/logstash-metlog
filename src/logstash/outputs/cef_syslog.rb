#!/usr/bin/env ruby

require 'syslog'

class SyslogSender

    _SYSLOG_OPTIONS = {'PID' => Syslog::LOG_PID,
                       'CONS' => Syslog::LOG_CONS,
                       'NDELAY' => Syslog::LOG_NDELAY,
                       'NOWAIT'=>  Syslog::LOG_NOWAIT}

    _SYSLOG_PRIORITY = {'EMERG' => Syslog::LOG_EMERG,
                        'ALERT' => Syslog::LOG_ALERT,
                        'CRIT' => Syslog::LOG_CRIT,
                        'ERR' => Syslog::LOG_ERR,
                        'WARNING' => Syslog::LOG_WARNING,
                        'NOTICE' => Syslog::LOG_NOTICE,
                        'INFO' => Syslog::LOG_INFO,
                        'DEBUG' => Syslog::LOG_DEBUG}

    _SYSLOG_FACILITY = {'KERN' => Syslog::LOG_KERN,
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
    def initialize(ident, options, facility)
        Syslog.open(ident, options, facility)
    end

    public
    def log_msg(msg, config)
        # logs a message to syslog
        logopt = _str2logopt(config['syslog_options'])
        facility = _str2facility(config['syslog_facility'])
        ident = config['syslog_ident']
        priority = _str2priority(config['syslog.priority'])
        Syslog.log(priority, msg)
    end


    def _str2logopt(value)
        if value is nil
            return 0
        end
        res = 0
        value.split(',') { |option|
            res = res | _SYSLOG_OPTIONS[option.strip]
        }
        return res
    end

    def _str2priority(value)
        if value is nil
            return Syslog::LOG_INFO
        end
        return _SYSLOG_PRIORITY[value.strip]
    end


    def _str2facility(value)
        if value is None
            return Syslog::LOG_LOCAL4
        else
            return _SYSLOG_FACILITY[value.strip]
        end
    end
end

