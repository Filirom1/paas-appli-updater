%define _topdir /usr/src/rpmbuild
%define prefix /usr/local
%define prefix2 /
%define sources /usr/local/paas-appli-updater/paas
%define sources2 /usr/local/paas-appli-updater/etc

Name:           paas-appli-updater
Version:        0.2
Release:        1
%define buildroot %{_topdir}/%{name}-%{version}
Summary:        Applications update Process on reverses proxies

Group:          Applications/Paas
BuildArch:			noarch
License:        Apache
URL:            http://worldline.com
BuildRoot:      %{buildroot}
Source0:		/usr/local/paas-appli-updater/paas
Prefix:		%{prefix}

#BuildRequires:  
require 'rubygems'
require 'stomp'
require 'mcollective'
require 'pp'
require 'logger'
require 'broker'
require 'node'
require 'rproxy'
require 'config'
require 'paasexceptions'

Requires:       paas-libs >= 0.2.0
Requires:				ruby193-rubygems >= 1.8.24
Requires:				ruby193-rubygem-stomp >= 1.1.8
Requires:				ruby193-mcollective-common >= 2.2.3

%description
Paas: Applications update Process on reverses proxies

%prep
rm -rf %{name}
mkdir %{name}
%__cp -Rp %{sources} %{sources2} %{name}

%install
mkdir -p ${RPM_BUILD_ROOT}/%{prefix}
mkdir -p ${RPM_BUILD_ROOT}/%{prefix2}
%__cp -Rp %{name}/paas ${RPM_BUILD_ROOT}/%{prefix}
%__cp -Rp %{name}/etc ${RPM_BUILD_ROOT}/%{prefix2}


%clean
# rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/usr/local/paas/bin/configProxy.rb
/usr/local/paas/bin/configProxyService.rb
/etc/init.d/paas-configProxy 

%config

%post

%postun

%changelog
* Mon Oct 11 2013 - 0.2 - a186643
- Update version to push sources to github
* Mon Jun 30 2013 - 0.1.1 - a186643
- Version modifiée suite install sur openshift version nightly build 
* Mon Jun 30 2013 - 0.1 - a186643
- Version initiale

