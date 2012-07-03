build_rpm:
	mkdir -p build/SOURCES
	rm -rf build/RPMS build/logstash-metlog-*
	tar czf build/SOURCES/logstash-metlog.tar.gz src/logstash logrotate/bin
	rpmbuild --define "_topdir $$PWD/build" -ba rpm/logstash-metlog.spec
	cp build/RPMS/*/*.rpm build/
	ls -l build/logstash-metlog-*.rpm
