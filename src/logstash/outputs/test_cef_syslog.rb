
require "test/unit"
require "mocha"
require 'cef_syslog'
require 'syslog'

class MiscExampleTest < Test::Unit::TestCase
    def setup
        @sender = SyslogSender.new()
    end

    def teardown
        @sender.close
    end

    def test_mocking_a_class_method
        config = {'syslog_options' => 'NOWAIT,PID',
            'syslog_facility' => nil,
            'syslog_ident' => 'some_identity',
            'syslog_priority' => 'ALERT',}


        # LOGLOCAL4 facility == 160
        # NOWAIT|PID == 17
        # ALERT == priority 1
        Syslog.expects(:open).with('some_identity', 17, 160)
        Syslog.expects(:log).with(1, 'foo')
        @sender.log_msg('foo', config)

        config['syslog_priority'] = 'EMERG'
        # 2nd message will not open the syslog again, but will send
        # the message
        Syslog.expects(:log).with(0, 'bar')
        @sender.log_msg('bar', config)
    end

    def test_mutating_config
        config = {'syslog_options' => 'NOWAIT,PID',
            'syslog_facility' => nil,
            'syslog_ident' => 'some_identity',
            'syslog_priority' => 'ALERT',}


        # LOGLOCAL4 facility == 160
        # NOWAIT|PID == 17
        # ALERT == priority 1
        Syslog.expects(:open).with('some_identity', 17, 160)
        Syslog.expects(:log).with(1, 'foo')
        @sender.log_msg('foo', config)

        # New config for identity, options and facility
        config = {'syslog_options' => 'NDELAY',
            'syslog_facility' => 'MAIL',
            'syslog_ident' => 'another_ident',
            'syslog_priority' => 'NOTICE',}
        Syslog.expects(:open).with('another_ident', 8, 16)
        Syslog.expects(:log).with(5, 'foo')
        @sender.log_msg('foo', config)
    end
end
