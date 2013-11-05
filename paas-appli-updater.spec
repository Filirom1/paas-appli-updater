%global paasdir %{_libdir}/paas-appli-updater

Name:           paas-appli-updater
Version:        0.4
Release:        1%{?dist}
Summary:        Applications update Process on reverses proxies
Source0:        https://github.com/worldline/%{name}/archive/master.tar.gz

Group:          Applications/Paas
BuildArch:      noarch
License:        Apache
URL:            http://worldline.com


# TODO clean it

#BuildRequires:  
#require 'rubygems'
#require 'stomp'
#require 'mcollective'
#require 'pp'
#require 'logger'
#require 'broker'
#require 'node'
#require 'rproxy'
#require 'config'
#require 'paasexceptions'
#
#Requires:       paas-libs >= 0.2.0
#Requires:       ruby193-rubygems >= 1.8.24
#Requires:       ruby193-rubygem-stomp >= 1.1.8
#Requires:       ruby193-mcollective-common >= 2.2.3


%description
Paas: Applications update Process on reverses proxies

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{paasdir}
%__cp -r * %{buildroot}%{paasdir}

%__mkdir -p %{buildroot}%{_sysconfdir}
%__cp conf/%{name}.conf %{buildroot}%{_sysconfdir}

#TODO systemd
%__mkdir -p %{buildroot}%{_initddir}
%__mv %{buildroot}%{paasdir}/init.d/* %{buildroot}%{_initddir}
%__rm -rf %{buildroot}%{paasdir}/init.d


%files
%doc %{paasdir}/LICENSE
%doc %{paasdir}/README.md
%doc %{paasdir}/paas-ha.jpg
%config(noreplace) %{_sysconfdir}/%{name}.conf

%{paasdir}

#TODO systemd
%{_initddir}/%{name}

%changelog
* Tue Nov 05 2013 Filirom1 <Filirom1@gmail.com> 0.4-1
- add default configuration (Filirom1@gmail.com)
- clean dependencies (Filirom1@gmail.com)
- use relative path (Filirom1@gmail.com)
- add missing quotes (Filirom1@gmail.com)
- OpenShift code style is to use 2 spaces instead of tab (Filirom1@gmail.com)
- merge paas-lib (Filirom1@gmail.com)

* Mon Nov 04 2013 Filirom1 <Filirom1@gmail.com> 0.3-1
- new package built with tito

* Mon Oct 11 2013 - 0.2 - a186643
- Update version to push sources to github
* Mon Jun 30 2013 - 0.1.1 - a186643
- Version modifiée suite install sur openshift version nightly build 
* Mon Jun 30 2013 - 0.1 - a186643
- Version initiale

