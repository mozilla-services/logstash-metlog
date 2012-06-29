#!/bin/python
import datetime
import subprocess
import shutil
import os
import sys
from metlog.config import client_from_text_config 
import ConfigParser

#sender_class = metlog.senders.ZmqPubSender 
#sender_bindstrs = tcp://127.0.0.1:5565 
cfg_txt = """[metlog] 
logger = metlog_hadoop_transport
sender_class = metlog.senders.StdOutSender
""" 

HADOOP_USER = 'sync_dev'
HADOOP_HOST = 'research-gw.research.metrics.scl3.mozilla.com'

SDATE = datetime.datetime.utcnow().strftime('%Y%m%d_%H%M%S')
DST_FNAME="hadoop_logs/metrics_hdfs.log.%s" % SDATE

SRC_LOGFILE = '/var/log/sync/metrics_hdfs.log.1'

# Make a copy of the log file in case it gets rotated out from under us
LOCAL_FNAME="/opt/metlog/hdfs_logs/metrics_hdfs.log.%s" % SDATE

#############################
#############################
#############################

LOGGER = client_from_text_config(cfg_txt, 'metlog') 

def remove_file_from_hadoop():
    rm_cmd = ["ssh", 
      "%s@%s" % (HADOOP_USER, HADOOP_HOST),
      "rm", 
      DST_FNAME]
    # try to clean up the file off of the metrics server 
    print ' '.join(rm_cmd)
    rm_result = subprocess.call(rm_cmd)
    if rm_result != 0:
        LOGGER.error('Failed to remove [%s] from %s after DFS write failure' % (DST_FNAME, HADOOP_HOST))    

def cleanup_local():
    try:
        os.remove(LOCAL_FNAME)
    except Exception, e:
        LOGGER.error("Error removing: [%s]: %s" % (LOCAL_FNAME, e))

def copy_log_local():
    try:
        shutil.copy(SRC_LOGFILE, LOCAL_FNAME)
    except:
        LOGGER.error("Error copying JSON log file for processing")
        sys.exit(1)

def push_to_hadoop_host():
    scp_cmd = ["scp",
               LOCAL_FNAME,
              "%s@%s:%s" % (HADOOP_USER, HADOOP_HOST, DST_FNAME),]
    print ' '.join(scp_cmd)
    scp_result = subprocess.call(scp_cmd)

    if scp_result != 0:
        LOGGER.error("Transport to HDFS cluster failed.  Filename: [%s]" % DST_FNAME)
        sys.exit(1)

def dfs_put():
    # Just tell hadoop to import the file
    cmd = ["ssh", 
      "%s@%s" % (HADOOP_USER, HADOOP_HOST),
      "hadoop", 
      "dfs", 
      "-put", 
      DST_FNAME, 
      "/user/%s/%s" % (HADOOP_USER, DST_FNAME)]

    dfs_result = subprocess.call(cmd)

    if dfs_result != 0:
        remove_file_from_hadoop()
        LOGGER.error("DFS Write failure for [%s]" % DST_FNAME)
        sys.exit(1)
    else:
        remove_file_from_hadoop()
        cleanup_local()

copy_log_local()
push_to_hadoop_host()
dfs_put()
