#!/bin/sh
java -jar lib/logstash-1.1.0beta4-monolithic.jar agent -vvv -f config/tagfilter.conf --pluginpath src
