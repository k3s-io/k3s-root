FROM ubuntu:18.04 AS ubuntu
RUN yes | unminimize
RUN apt-get update # 03/8/2019
RUN apt-get install -y \
    build-essential \
    ccache \
    gcc \
    git \
    g++ \
    rsync \
    bc \
    wget \
    curl \
    ca-certificates \
    ncurses-dev \
    python \
    unzip
RUN mkdir /usr/src/buildroot
RUN curl -fL https://buildroot.org/downloads/buildroot-2018.11.1.tar.bz2 | tar xvjf - -C /usr/src/buildroot --strip-components=1
RUN curl -fL https://storage.googleapis.com/buildroot-cache/2018.11.1.tar.gz | tar xvzf - -C /usr/src/buildroot
WORKDIR /usr/src/buildroot
COPY conntrack-tools/* /usr/src/buildroot/package/conntrack-tools/
COPY slirp4netns/* /usr/src/buildroot/package/slirp4netns/
COPY busybox.config /usr/src/buildroot/package/busybox/
COPY package/Config.in /usr/src/buildroot/package/

ARG ARCH=x86_64
COPY buildroot/config /usr/src/buildroot/.config
COPY buildroot/${ARCH}config /usr/src/buildroot/.config-arch
RUN cat .config-arch >> .config && \
    make oldconfig
RUN make
RUN cd .. && \
    mkdir bin && \
    cp buildroot/output/target/usr/sbin/xtables-multi bin/ && \
    cp buildroot/output/target/usr/sbin/conntrack bin/ && \
    cp buildroot/output/target/usr/sbin/ipset bin/ && \
    cp buildroot/output/target/usr/bin/pigz bin/ && \
    cp buildroot/output/target/usr/bin/slirp4netns bin/ && \
    cp buildroot/output/target/usr/bin/socat bin/ && \
    cp buildroot/output/target/sbin/ip bin/ && \
    cp buildroot/output/target/sbin/ebtables bin/ && \
    cp buildroot/output/target/bin/busybox bin/
RUN cd ../bin && \
    for i in '[' '[[' addgroup adduser ar arch arp arping ash awk basename blkid bunzip2 bzcat cat chattr chgrp chmod chown chroot chrt chvt cksum clear cmp cp cpio crond crontab cut date dc dd deallocvt delgroup deluser devmem df diff dirname dmesg dnsd dnsdomainname dos2unix du dumpkmap echo egrep eject env ether-wake expr factor fallocate false fbset fdflush fdformat fdisk fgrep find flock fold free freeramdisk fsck fsfreeze fstrim fuser getopt getty grep gunzip gzip halt hdparm head hexdump hexedit hostid hostname hwclock i2cdetect i2cdump i2cget i2cset id ifconfig ifdown ifup inetd init insmod install ip ipaddr ipcrm ipcs iplink ipneigh iproute iprule iptunnel kill killall killall5 klogd last less link linux32 linux64 linuxrc ln loadfont loadkmap logger login logname losetup ls lsattr lsmod lsof lspci lsscsi lsusb lzcat lzma lzopcat makedevs md5sum mdev mesg microcom mkdir mkdosfs mke2fs mkfifo mknod mkpasswd mkswap mktemp modprobe more mount mountpoint mt mv nameif netstat nice nl nohup nproc nsenter nslookup nuke od openvt partprobe passwd paste patch pidof ping pipe_progress pivot_root poweroff printenv printf ps pwd rdate readlink readprofile realpath reboot renice reset resize resume rm rmdir rmmod route run-init run-parts runlevel sed seq setarch setconsole setfattr setkeycodes setlogcons setpriv setserial setsid sh sha1sum sha256sum sha3sum sha512sum shred sleep sort start-stop-daemon strings stty su sulogin svc svok swapoff swapon switch_root sync sysctl syslogd tail tar tc tee telnet test tftp time top touch tr traceroute true truncate tty ubirename udhcpc uevent umount uname uniq unix2dos unlink unlzma unlzop unxz unzip uptime usleep uudecode uuencode vconfig vi vlock w watch watchdog wc wget which who whoami xargs xxd xz xzcat yes zcat; do ln -s busybox $i; done && \
    for i in iptables iptables-save iptables-restore; do ln -s xtables-multi $i; done
