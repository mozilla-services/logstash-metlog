all:
	cp logstash-1.1.0beta4-monolithic.jar logstash-custom.jar
	jar uvf logstash-custom.jar logstash/filters/foo.rb
	jar uvf logstash-custom.jar logstash/filters/tagger.rb
	jar uvf logstash-custom.jar logstash/inputs/udp.rb
	jar uvf logstash-custom.jar logstash/inputs/zeromq.rb
