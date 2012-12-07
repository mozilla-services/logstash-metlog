HDFS Configuration
==================

Deployment notes for setting up metlog-json logs so that they get pushed into HDFS

You'll need a couple pieces in play:

    #. logstash
    #. logrotate
    #. Metlog enabled application

Instructions:

#. Ensure that JSON logs are rotated properly and being written out to:

  * /var/log/<your_app>/metrics_hdfs.log=%Y-%m-%d

  Example:

  * /var/log/sync_web/metrics_hdfs.log=2012-03-20

#. Make sure you've got the filename correct - specifically that the
   logrotation is *not* compressing with gzip.


#. Put a copy of metrics_hdfs.ini file into /etc/mozilla-services/metlog/metrics_hdfs.ini

    A sample INI file is below ::

        # This configuration file is used by the scheduled job to push
        # JSON logs to HDFS
        [metlog]
        logger = metlog_hadoop_transport
        sender_class = metlog.senders.StdOutSender
        [metlog_metrics_hdfs]
        HADOOP_USER = sync_dev
        HADOOP_HOST = 10.1.1.10 # Put your Hadoop SSH host here
        SRC_LOGFILE = /var/log/syncweb/metrics_hdfs.log=%%Y-%%m-%%d.gz
        DST_FNAME = hadoop_logs/metrics_hdfs.log
        TMP_DIR = /opt/logstash/hdfs_logs

#. Ensure that the HADOOP_USER has been provisioned within the Hadoop cluster and that the SSH public keys have been installed into LDAP.

#. Ensure that upload_log.py is installed into /opt/logstash/bin/upload_log.py
   This should have been installed when you installed the
   logstash-metlog RPM.

#. Install private SSH keys for HADOOP_USER into /opt/logstash/ssh-keys

  * Make sure that the identify file (the private key) is named "id_private_<HADOOP_USER>" For the previous metrics_hdfs.ini file,
    that means your identify file is ::

        /opt/logstash/ssh-keys/id_private_sync_dev

#. Setup the logrotate daily job.  A sample configuration is shown
below. ::

    ## Managed by puppet
    /var/log/syncweb/application.log /var/log/syncweb/metrics_hdfs.log {
        daily
        compress
        copytruncate
        dateext
        dateformat=%Y-%m-%d
        rotate 7
        postrotate 
            /opt/logstash/bin/upload_log.py \
              --ssh-keys=/opt/logstash/ssh-keys \
              --config /etc/mozilla-services/metlog/metrics_hdfs.ini \
              && /usr/bin/pkill -HUP logstash 
        endscript 
    }

You'll also need to have 2 directories setup for HDFS pushes to work
correctly :

DST_FNAME:

    The DST_FNAME in metrics_hdfs.ini refers to a relative path from the home directory of the HADOOP_USER.
    In the metrics_hdfs.ini file in this example, the 'hadoop_logs/metrics_hdfs.log' value will be mapped to:
    /home/sync_dev/hadoop_logs/metrics_hdfs.log.<TIMESTAMP>

    The <TIMESTAMP> will be replaced with the timestamp that the logfile was moved.

TMP_DIR:

    TMP_DIR is a path on the local filesystem from the machine pushing logs to HDFS.
    This directory will get a copy of the log file that will be pushed to HDFS.  On successful push to HDFS, the log file will be removed from TMP_DIR, but unsuccessful pushes will leave the log file in the TMP_DIR.
