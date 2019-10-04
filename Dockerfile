FROM ubuntu:18.04 AS ubuntu
RUN yes | unminimize
RUN apt-get update
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
RUN curl -fL https://buildroot.org/downloads/buildroot-2019.02.6.tar.bz2 | tar xvjf - -C /usr/src/buildroot --strip-components=1
WORKDIR /usr/src/buildroot
COPY conntrack-tools/* /usr/src/buildroot/package/conntrack-tools/
COPY slirp4netns/* /usr/src/buildroot/package/slirp4netns/
COPY strongswan/* /usr/src/buildroot/package/strongswan/
COPY busybox.config /usr/src/buildroot/package/busybox/
COPY package/Config.in /usr/src/buildroot/package/

ARG ARCH=amd64
COPY buildroot/config /usr/src/buildroot/.config
COPY buildroot/${ARCH}config /usr/src/buildroot/.config-arch
RUN cat .config-arch >> .config && \
    make oldconfig
RUN make
RUN cd .. && \
    mkdir bin && \
    cp buildroot/output/target/usr/sbin/xtables-legacy-multi bin/ && \
    cp buildroot/output/target/usr/sbin/conntrack bin/ && \
    cp buildroot/output/target/usr/sbin/ipset bin/ && \
    cp buildroot/output/target/usr/bin/find bin/ && \
    cp buildroot/output/target/usr/bin/pigz bin/ && \
    cp buildroot/output/target/usr/bin/slirp4netns bin/ && \
    cp buildroot/output/target/usr/bin/socat bin/ && \
    cp buildroot/output/target/usr/bin/coreutils bin/ && \
    cp buildroot/output/target/sbin/ip bin/ && \
    cp buildroot/output/target/sbin/ebtables bin/ && \
    cp buildroot/output/target/bin/busybox bin/

# strongswan
RUN cd .. && \
    cp buildroot/output/target/usr/sbin/swanctl bin/ && \
    cp buildroot/output/target/usr/libexec/ipsec/charon bin/

# save strongswan etc config
RUN cd .. && \
    mkdir etc && \
    cp -rp buildroot/output/target/var/lib/rancher/k3s/agent/* etc/

RUN cd ../bin && \
    for i in addgroup adduser ar arch arp arping ash awk basename blkid bunzip2 bzcat cat chattr chgrp chmod chown chroot chrt chvt cksum clear cmp cp cpio crond crontab cut date dc dd deallocvt delgroup deluser devmem df diff dirname dmesg dnsd dnsdomainname dos2unix du dumpkmap echo egrep eject env ether-wake expr factor fallocate false fbset fdflush fdformat fdisk fgrep flock fold free freeramdisk fsck fsfreeze fstrim fuser getopt getty grep gunzip gzip halt hdparm head hexdump hexedit hostid hostname hwclock i2cdetect i2cdump i2cget i2cset id ifconfig ifdown ifup inetd init insmod install ipaddr ipcrm ipcs iplink ipneigh iproute iprule iptunnel kill killall killall5 klogd last less link linux32 linux64 linuxrc ln loadfont loadkmap logger login logname losetup ls lsattr lsmod lsof lspci lsscsi lsusb lzcat lzma lzopcat makedevs md5sum mdev mesg microcom mkdir mkdosfs mke2fs mkfifo mknod mkpasswd mkswap mktemp modprobe more mount mountpoint mt mv nameif netstat nice nl nohup nproc nsenter nslookup nuke od openvt partprobe passwd paste patch pidof ping pipe_progress pivot_root poweroff printenv printf ps pwd rdate readlink readprofile realpath reboot renice reset resize resume rm rmdir rmmod route run-init run-parts runlevel sed seq setarch setconsole setfattr setkeycodes setlogcons setpriv setserial setsid sh sha1sum sha256sum sha3sum sha512sum shred sleep sort start-stop-daemon strings stty su sulogin svc svok swapoff swapon switch_root sync sysctl syslogd tail tar tc tee telnet test tftp time top touch tr traceroute true truncate tty ubirename udhcpc uevent umount uname uniq unix2dos unlink unlzma unlzop unxz unzip uptime usleep uudecode uuencode vconfig vi vlock w watch watchdog wc wget which who whoami xargs xxd xz xzcat yes zcat; do ln -s busybox $i; done && \
    for i in iptables iptables-save iptables-restore; do ln -s xtables-legacy-multi $i; done && \
    for i in b2sum base32 base64 basename cat chcon chgrp chmod chown chroot cksum comm cp csplit cut date dd df dir dircolors dirname du echo env expand expr factor false fmt fold ginstall groups head hostid id join kill link ln logname ls md5sum mkdir mkfifo mknod mktemp mv nice nl nohup nproc numfmt od paste pathchk pinky pr printenv printf ptx pwd readlink realpath rm rmdir runcon seq sha1sum sha224sum sha256sum sha384sum sha512sum shred shuf sleep sort split stat stty sum sync tac tail tee test timeout touch tr true truncate tsort tty uname unexpand uniq unlink uptime users vdir wc who whoami yes; do ln -sf coreutils $i; done
