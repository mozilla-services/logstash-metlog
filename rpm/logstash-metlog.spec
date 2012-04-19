%define _logstash_dir /opt/logstash

Name:          logstash-metlog
Version:       0.2
Release:       1
Summary:       Logstash plugins for the MetLog framework
Packager:      Pete Fritchman <petef@mozilla.com>
Group:         Development/Libraries
License:       MPL 2.0
URL:           https://github.com/mozilla-services/logstash-metlog
Source0:       %{name}.tar.gz
BuildRoot:     %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
AutoReqProv:   no
Requires:      logstash

%description
Logstash plugins to enable messages coming from the MetLog framework
to be properly parsed, filtered, and shipped.

%prep
%setup -q -c -n logstash-metlog

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_logstash_dir}/plugins
cp -rp src/logstash/* %{buildroot}%{_logstash_dir}/plugins

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{_logstash_dir}/plugins

%changelog
* Tue Apr 10 2012 Pete Fritchman <petef@mozilla.com>
- Initial package
