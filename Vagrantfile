################################################################################
#
# Vagrantfile
#
################################################################################

# Buildroot version to use
# RELEASE='2019.05.1'
RELEASE='2019.02.6'

### Change here for more memory/cores ###
VM_MEMORY=4096
VM_CORES=4

PROJECT_DIR="/vbox"
ARCH="amd64"

plugin_installed = false
required_plugins = %w( vagrant-vbguest )

required_plugins.each do |plugin|
  unless Vagrant.has_plugin?(plugin)
    system "vagrant plugin install #{plugin}"
    plugin_installed = true
  end
end

if plugin_installed === true
	exec "vagrant #{ARGV.join' '}"
end

Vagrant.configure('2') do |config|
	config.vm.box = 'ubuntu/bionic64'

	config.vm.provider :vmware_fusion do |v, override|
		v.vmx['memsize'] = VM_MEMORY
		v.vmx['numvcpus'] = VM_CORES
	end

	config.vm.synced_folder ".", PROJECT_DIR

	config.vm.provider :virtualbox do |v, override|
		v.memory = VM_MEMORY
		v.cpus = VM_CORES
	end

	config.vm.provision 'shell' do |s|
		s.inline = 'echo Setting up machine name'

		config.vm.provider :vmware_fusion do |v, override|
			v.vmx['displayname'] = "Buildroot #{RELEASE}"
		end

		config.vm.provider :virtualbox do |v, override|
			v.name = "Buildroot #{RELEASE}"
		end
	end

	config.vm.provision 'shell', privileged: true, inline:
		"
		sed -i 's|deb http://us.archive.ubuntu.com/ubuntu/|deb mirror://mirrors.ubuntu.com/mirrors.txt|g' /etc/apt/sources.list
		dpkg --add-architecture i386
		apt-get -q update
		apt-get purge -q -y snapd lxcfs lxd ubuntu-core-launcher snap-confine
		UCF_FORCE_CONFOLD=1 \
		DEBIAN_FRONTEND=noninteractive \
		apt-get -o 'Dpkg::Options::=--force-confdef' -o 'Dpkg::Options::=--force-confold' -qq -y install \
			build-essential \
			libncurses5-dev \
			git \
			bzr \
			cvs \
			mercurial \
			subversion \
			libc6:i386 \
			unzip \
			bc \
			ccache \
			gcc \
			g++ \
			rsync \
			wget \
			curl \
			ca-certificates \
			ncurses-dev \
			python \

		apt-get -q -y autoremove
		apt-get -q -y clean
		update-locale LC_ALL=C
		"

	config.vm.provision 'shell', privileged: false, inline:
		"
		echo 'Downloading and extracting buildroot #{RELEASE}'
		sudo mkdir -m 777 -p /usr/src/buildroot
		curl -sL https://buildroot.org/downloads/buildroot-#{RELEASE}.tar.bz2 | tar xvjf - -C /usr/src/buildroot --strip-components=1
		"

	config.vm.provision 'shell', privileged: false, inline:
		"
		cd #{PROJECT_DIR}
		cp package/Config.in /usr/src/buildroot/package/
	
		mkdir -p /usr/src/buildroot/package/conntrack-tools/
		cp conntrack-tools/* /usr/src/buildroot/package/conntrack-tools/
	
		mkdir -p /usr/src/buildroot/package/slirp4netns/
		cp slirp4netns/* /usr/src/buildroot/package/slirp4netns/

		mkdir -p /usr/src/buildroot/package/strongswan/
		cp strongswan/* /usr/src/buildroot/package/strongswan/

		mkdir -p /usr/src/buildroot/package/busybox/
		cp busybox.config /usr/src/buildroot/package/busybox/

		cat buildroot/config buildroot/#{ARCH}config >/usr/src/buildroot/.config

		cd /usr/src/buildroot/
		# make oldconfig
		"

end
