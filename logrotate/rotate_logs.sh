#!/bin/sh

# Add /usr/local/bin to  PATH so that we can pick up daemontools
export PATH=$PATH:/usr/local/bin
export DTSTAMP_LOG=`date "+%Y%m%d_%H%M%S"`.json.log

svc -h /service/logstash
hadoop fs -copyFromLocal /var/log/metlog/metlog_hdfs.log.1 /user/vng/$DTSTAMP_LOG
