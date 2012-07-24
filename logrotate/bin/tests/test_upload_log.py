import sys
sys.path.append("..")
import upload_log
from ConfigParser import SafeConfigParser
import StringIO
from mock import patch
from nose.tools import eq_


class TestUploader(object):
    def setUp(self):
        self.config = SafeConfigParser()
        cfg = StringIO.StringIO("""
# This configuration file is used by the scheduled job to push
# JSON logs to HDFS

[metlog]
logger = metlog_hadoop_transport
sender_class = metlog.senders.StdOutSender

[metlog_metrics_hdfs]
HADOOP_USER = aitc_dev
HADOOP_HOST = research-gw.research.stage.metrics.scl3.mozilla.com
SRC_LOGFILE = /var/log/aitc/metrics_hdfs.log=%%Y-%%m-%%d.gz
DST_FNAME = hadoop_logs/metrics_hdfs.log
TMP_DIR = /opt/logstash/hdfs_logs
        """)
        self.config.readfp(cfg)

    def test_upload_hdfs(self):
        sdate_patch = patch.object(upload_log.HDFSUploader, 'compute_sdate',
                lambda self: '20120723')
        sdate_patch.start()

        loader = upload_log.HDFSUploader(self.config)

        class MockSubprocess(object):
            def __init__(self):
                self._calls = []

            def __call__(self, *args, **kwargs):
                self._calls.append((args, kwargs))
                return 0

        subprocess_patcher = patch.object(loader,
                'call_subprocess', new_callable=MockSubprocess)

        subprocess_patcher.start()

        copy_patcher = patch.object(loader,
                'copy_log_local')
        copy_patcher.start()

        remove_patcher = patch.object(loader,
                'remove_log_local')
        remove_patcher.start()

        cleanup_patcher = patch.object(loader,
                'cleanup_local')
        cleanup_patcher.start()

        logger_patcher = patch.object(loader,
                'LOGGER')
        logger_patcher.start()

        loader.copy_log_local()
        loader.push_to_hadoop_host()
        loader.dfs_put()
        loader.remove_log_local()

        method_calls = [args[0] for (args, kwargs) in \
                loader.call_subprocess._calls]

        expected = [['scp',
                    '/opt/logstash/hdfs_logs/metrics_hdfs.log.20120723',
                    'aitc_dev@research-gw.research.stage.metrics.scl3.mozilla.com:hadoop_logs/metrics_hdfs.log.20120723'],  # NOQA
                    ['ssh',
                    'aitc_dev@research-gw.research.stage.metrics.scl3.mozilla.com',   # NOQA
                    'hadoop', 'dfs', '-put',
                    'hadoop_logs/metrics_hdfs.log.20120723',
                    '/user/aitc_dev/hadoop_logs/metrics_hdfs.log.20120723'],
                    ['ssh',
                    'aitc_dev@research-gw.research.stage.metrics.scl3.mozilla.com',   # NOQA
                    'rm', 'hadoop_logs/metrics_hdfs.log.20120723']]
        eq_(method_calls, expected)
