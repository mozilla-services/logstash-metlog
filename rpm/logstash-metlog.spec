%define _logstash_dir /opt/logstash

Name:          logstash-metlog
Version:       0.8.9
Release:       1svc
Summary:       Logstash plugins for the MetLog framework
Packager:      Mozilla Services Operations <services-ops@mozilla.com>
Group:         Development/Libraries
License:       MPL 2.0
URL:           https://github.com/mozilla-services/logstash-metlog
Source0:       %{name}.tar.gz
BuildRoot:     %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
AutoReqProv:   no
Requires:      logstash = 1.1.5-2svc, python26-argparse

%description
Logstash plugins to enable messages coming from the MetLog framework
to be properly parsed, filtered, and shipped.

%prep
%setup -q -c -n logstash-metlog

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_logstash_dir}/plugins
mkdir -p %{buildroot}%{_logstash_dir}/bin
cp -rp src/logstash %{buildroot}%{_logstash_dir}/plugins
cp -p logrotate/bin/upload_log.py %{buildroot}%{_logstash_dir}/bin

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{_logstash_dir}/plugins
%attr(755,root,root) %{_logstash_dir}/bin/upload_log.py

%changelog
* Thu Dec 27 2012 Wesley Dawson <whd@mozilla.com>
- Update specfile for 0.8.9

* Thu Nov 22 2012 Victor Ng <vng@mozilla.com>
- release 0.8.8
- use fully qualified paths for scp and ssh
- fixed some bad dates in the RPM changelog

* Wed Nov 21 2012 Victor Ng <vng@mozilla.com>
- release 0.8.7
- modified upload_log.py to support using SSH identity files not
  associated with the user running the python script.
- removed a superfluous error message when cleaning up temporary log
  files

* Mon Oct 1 2012 Victor Ng <vng@mozilla.com>
- release 0.8.6
- added support for CEF over syslog
- added support for Sentry messages over UDP with a special metlog_sentry_dsn output plugin

* Fri Aug 10 2012 Victor Ng <vng@mozilla.com>
- release 0.8.5
- fixed a bug with namespace handling where a double '.' would show up

* Tue Jul 24 2012 Victor Ng <vng@mozilla.com>
- release 0.8.4
- JSON log push now has the ability to handle date formatting by logrotate

* Thu Jul 19 2012 Victor Ng <vng@mozilla.com>
- release 0.8.3
- Added a UDP input plugin that will play nice with gevent

* Tue Jul 10 2012 Victor Ng <vng@mozilla.com>
- release 0.8.2
- Added exception handling around the sentry plugin.  Failed transport
  to sentry will result in messages going to logstash's default logger

* Tue Jul 3 2012 Victor Ng <vng@mozilla.com>
- release 0.8.1
- Added a new HDFS upload script
- Added dependency on python26-argparse for HDFS uploads

* Tue Jun 26 2012 Victor Ng <vng@mozilla.com>
- release 0.8
- No code changes.  Just added a requirement on 1.2.0 > logstash >= 1.1.0

* Fri Jun 22 2012 Victor Ng <vng@mozilla.com>
- release 0.7
- embedded the ruby-hmac 0.4 to support hmac-sha1 digests for Sentry
  messages
- added a new 'catchall' filter so that messages types that would
  normally not be tagged to be routed to an output plugin can now be
  send to a default output plugin.

* Wed Jun 20 2012 Victor Ng <vng@mozilla.com>
- release 0.6
- fixed bugs in metlog_file output plugin to address arbitrary keys in
  the JSON blob to send to the text output

* Tue Jun 19 2012 Victor Ng <vng@mozilla.com>
 - release 05.
 - added ISO8601 timestamp prefix options to metlog_file

* Wed Jun 13 2012 Victor Ng <vng@mozilla.com>
- release 0.4
- fixed bugs in metlog_file output plugin to address arbitrary keys in
  the JSON blob to send to the text output

* Tue Apr 10 2012 Pete Fritchman <petef@mozilla.com>
- Initial package
