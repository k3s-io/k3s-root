################################################################################
#
# Vagrantfile
#
################################################################################

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
		BUILDROOT_VERSION=$(grep BUILDROOT_VERSION #{PROJECT_DIR}/Dockerfile | cut -f2 -d=)
		echo 'Downloading and extracting buildroot' ${BUILDROOT_VERSION}
		sudo mkdir -m 777 -p /usr/src/buildroot
		curl -sL https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.bz2 | tar xvjf - -C /usr/src/buildroot --strip-components=1
		"

	config.vm.provision 'shell', privileged: false, inline:
		"
		set -e -x
		cd /usr/src/buildroot/
		cat #{PROJECT_DIR}/buildroot/config #{PROJECT_DIR}/buildroot/#{ARCH}config >.config
		cp -a #{PROJECT_DIR}/package/. package/
		for p in #{PROJECT_DIR}/patches/*.patch; do patch -p1 -i $p; done

		# make oldconfig
		"

end
