%define _rootdir /opt

Name:           metlog-server
Version:        0.4
Release:        1%{?dist}
Summary:        JRuby plugin code for logstash to support metlog

Group:          Development/Libraries
License:        Mozilla Public License 2.0
URL:            http://pypi.python.org/pypi/metlog-py
Source0:        %{name}-%{version}.tar
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch:      noarch


%description
JRuby plugin code for logstash 1.1.0 to support the metlog codebase

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
cp -rp %{_builddir}/%{name}-%{version}/opt %{buildroot}

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
%{_rootdir}

%changelog
