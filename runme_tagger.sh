#!/bin/sh
java -jar lib/logstash-1.1.0-monolithic_master.jar agent -v -f config/tagfilter.conf --pluginpath src

