#!/bin/python
import datetime
import subprocess
import shutil
import os
import sys
from metlog.config import client_from_dict_config
from ConfigParser import SafeConfigParser


class HDFSUploader(object):
    def __init__(self, cfg):
        self._cfg = cfg

        self.SDATE = datetime.datetime.utcnow().strftime('%Y%m%d_%H%M%S')

        self.HADOOP_USER = cfg.get('metlog_metrics_hdfs', 'HADOOP_USER')
        self.HADOOP_HOST = cfg.get('metlog_metrics_hdfs', 'HADOOP_HOST')
        self.SRC_LOGFILE = cfg.get('metlog_metrics_hdfs', 'SRC_LOGFILE')

        self.DST_FNAME = "%s.%s" % (cfg.get('metlog_metrics_hdfs',
            'DST_FNAME'), self.SDATE)

        # Make a copy of the log file in case it gets rotated out from
        # under us
        self.LOCAL_FNAME = "/opt/metlog/hdfs_logs/metrics_hdfs.log.%s"
        self.LOCAL_FNAME = self.LOCAL_FNAME % self.SDATE

        self.ERR_RM_HDFS = 'Failed to remove [%s] from %s'
        self.ERR_RM_HDFS = self.ERR_RM_HDFS % \
                            (self.DST_FNAME, self.HADOOP_HOST)

        self.ERR_XFER_HADOOP = "Transport of [%s] to HDFS failed"
        self.ERR_XFER_HADOOP = self.ERR_XFER_HADOOP % self.DST_FNAME

        self.ERR_REMOVE_LOCAL = "Error removing: [%s]" % self.LOCAL_FNAME

        self.ERR_DFS_WRITE = "DFS Write failure for [%s]" % self.DST_FNAME

        self.LOGGER = client_from_dict_config(dict(cfg.items('metlog')))

    def remove_file_from_hadoop(self):
        rm_cmd = ["ssh",
          "%s@%s" % (self.HADOOP_USER, self.HADOOP_HOST),
          "rm",
          self.DST_FNAME]
        # try to clean up the file off of the metrics server
        print ' '.join(rm_cmd)
        rm_result = subprocess.call(rm_cmd)
        if rm_result != 0:
            self.LOGGER.error(self.ERR_RM_HDFS)

    def cleanup_local(self):
        try:
            os.remove(self.LOCAL_FNAME)
        except:
            self.LOGGER.error(self.ERR_REMOVE_LOCAL)

    def copy_log_local(self):
        try:
            shutil.copy(self.SRC_LOGFILE, self.LOCAL_FNAME)
        except:
            self.LOGGER.error("Error copying JSON log file for processing")
            sys.exit(1)

    def push_to_hadoop_host(self):
        scp_cmd = ["scp",
                   self.LOCAL_FNAME,
                  "%s@%s:%s" % (self.HADOOP_USER, self.HADOOP_HOST,
                      self.DST_FNAME)]
        scp_result = subprocess.call(scp_cmd)

        if scp_result != 0:
            self.LOGGER.error(self.ERR_XFER_HADOOP)
            sys.exit(1)

    def dfs_put(self):
        # Just tell hadoop to import the file
        cmd = ["ssh",
          "%s@%s" % (self.HADOOP_USER, self.HADOOP_HOST),
          "hadoop",
          "dfs",
          "-put",
          self.DST_FNAME,
          "/user/%s/%s" % (self.HADOOP_USER, self.DST_FNAME)]

        dfs_result = subprocess.call(cmd)

        if dfs_result != 0:
            self.remove_file_from_hadoop()
            self.LOGGER.error(self.ERR_DFS_WRITE)
            sys.exit(1)
        else:
            self.remove_file_from_hadoop()
            self.cleanup_local()


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Upload JSON logs to HDFS")
    parser.add_argument('--config', type=argparse.FileType('r'),
            required=True)

    parsed_args = parser.parse_args()

    cfg = SafeConfigParser()
    cfg.readfp(parsed_args.config)

    uploader = HDFSUploader(cfg)
    uploader.copy_log_local()
    uploader.push_to_hadoop_host()
    uploader.dfs_put()

if __name__ == '__main__':
    main()
