
require "test/unit"
require "mocha"
require 'cef_syslog'
require 'syslog'

class MiscExampleTest < Test::Unit::TestCase
    def setup
        @sender = SyslogSender.new()
    end

    def teardown
        if @sender.opened?
            @sender.close
        end
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

        #sender.log_msg('foo', config)
        # TODO: assert facility defaults to loglocal4
        # TODO: assert facility uses the facility map
        # TODO: assert identity is passed through
        # TODO: assert options are OR'd together
        # assert message was sent

        #sender.log_msg('bar', config)
        # assert message was sent

        #sender.log_msg('batz', config)
        # assert message was sent
    end

end
