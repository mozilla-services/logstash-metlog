all: jar
	./runme_tagger.sh

jar:
	cp logstash-1.1.0beta4-monolithic.jar logstash-custom.jar
	jar uvf logstash-custom.jar logstash/filters/tagger.rb
	jar uvf logstash-custom.jar logstash/inputs/zeromq.rb
	jar uvf logstash-custom.jar logstash/outputs/http.rb
