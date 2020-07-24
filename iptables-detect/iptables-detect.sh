#!/bin/sh

# Copyright 2019 The Kubernetes Authors.
# Copyright 2020 Rancher Labs
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script is only meant for use when operating in a non-containerized 
# environment but using non-host binaries (i.e. K3s with k3s-root), but 
# will fall back to operating in a containerized environment if necessary. 
# It relies on the underlying host system not having cgroups set up for PID 
# 1, as this is how it detects whether it is operating in a containerized 
# environment or not.

# Four step process to inspect for which version of iptables we're operating 
# with.
# 1. Detect whether we are operating in a containerized environment by inspecting cgroups for PID 1.
# 2. Run iptables-nft-save and iptables-legacy-save to inspect for rules. If 
# no rules are found from either binaries, then
# 3. Check /etc/alternatives/iptables on the host to see if there is a symlink 
# pointing towards the iptables binary we are using, if there is, run the 
# binary and grep it's output for version higher than 1.8 and "legacy" to see 
# if we are operating in legacy
# 4. Last chance is to do a rough check of the operating system, to make an 
# educated guess at which mode we can operate in.

# Bugs in iptables-nft 1.8.3 may cause it to get stuck in a loop in
# some circumstances, so we have to run the nft check in a timeout. To
# avoid hitting that timeout, we only bother to even check nft if
# legacy iptables was empty / mostly empty.

mode=unknown

detected_via=unknown

containerized=false

# Check to see if the nf_tables kernel module is loaded, if it is, we should operate in nft mode, else just fall back to legacy. This should only be run when in a container, ideally the klipper-lb container. 

nft_module_check() {
    lsmod | grep "nf_tables" 2> /dev/null
    if [ $? = 0 ]; then
        detected_via=modules
        mode=nft
    else
        detected_via=modules
        mode=legacy
    fi
}

# Check to see if we are containerized -- essentially look at the cgroup for PID 1 and check for things at the end of the "/" which indicates we are in a container (PID 1 shouldn't necessarily have a cgroup)

# there are two cases when we are containerized -- k3d and things that aren't k3s
is_containerized() {
    CGT=$(cat /proc/1/cgroup | grep "cpuset" | awk -F: '{print $3}' | sed 's/\///g'); 
    if [ -z $CGT ]; then
        containerized=false 
    else 
        containerized=true 
    fi
}

rule_check() {
    num_legacy_lines=$( (
        iptables-legacy-save || true
        ip6tables-legacy-save || true
    ) 2>/dev/null | grep '^-' | wc -l)
    if [ "${num_legacy_lines}" -ge 10 ]; then
        detected_via=rules
        mode=legacy
    else
        num_nft_lines=$( (timeout 5 sh -c "iptables-nft-save; ip6tables-nft-save" || true) 2>/dev/null | grep '^-' | wc -l)
        if [ "${num_legacy_lines}" -gt "${num_nft_lines}" ]; then
            detected_via=rules
            mode=legacy
        elif [ "${num_nft_lines}" = 0 ]; then
            mode=unknown
        else
            detected_via=rules
            mode=nft
        fi
    fi
}

alternatives_check() {
    readlink /etc/alternatives/iptables >/dev/null

    if [ $? = 0 ]; then
        readlink /etc/alternatives/iptables | grep -q "nft"
        if [ $? = 0 ]; then
            detected_via=alternatives
            mode=nft
        else
            detected_via=alternatives
            mode=legacy
        fi
    fi
}

# we should not run os-detect if we're being run inside of a container
os_detect() {
    # perform some very rudimentary platform detection
    lsb_dist=''
    dist_version=''
    if [ -z "$lsb_dist" ] && [ -r /etc/lsb-release ]; then
        lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/debian_version ]; then
        lsb_dist='debian'
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/fedora-release ]; then
        lsb_dist='fedora'
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/oracle-release ]; then
        lsb_dist='oracleserver'
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/centos-release ]; then
        lsb_dist='centos'
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/redhat-release ]; then
        lsb_dist='redhat'
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID")"
    fi

    lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

    # Special case redhatenterpriseserver
    if [ "${lsb_dist}" = "redhatenterpriseserver" ]; then
        # Set it to redhat, it will be changed to centos below anyways
        lsb_dist='redhat'
    fi

    case "$lsb_dist" in

    alpine)
        # Alpine is using iptables-legacy by default when you apk add iptables. There exists a iptables-nft subset of commands but they are not
        # used by default.
        detected_via=os
        mode=legacy
        ;;

    ubuntu)
        # By default, Ubuntu is using iptables in legacy mode. Ideally, this should have been already caught by the alternatives check.
        detected_via=os
        mode=legacy
        ;;

    debian | raspbian)
        dist_version="$(cat /etc/debian_version | sed 's/\/.*//' | sed 's/\..*//')"
        # If Debian >= 10 (Buster is 10), then NFT. otherwise, assume it is legacy
        if [ "$dist_version" -ge 10 ]; then
            detected_via=os
            mode=nft
        else
            detected_via=os
            mode=legacy
        fi
        ;;

    oracleserver)
        dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
        maj_ver=$(echo $dist_version | sed -E -e "s/^([0-9]+)\.?[0-9]*$/\1/")
        if [ "$maj_ver" -ge 8 ]; then
            detected_via=os
            mode=nft
        else
            detected_via=os
            mode=legacy
        fi
        ;;

    fedora)
        # As of 05/15/2020, all Fedora packages appeared to be still `legacy` by default although there is a `iptables-nft` package that installs the nft iptables, so look for that package.
        rpm -qa | grep -q "iptables-nft"
        if [ $? = 0 ]; then
            detected_via=os
            mode=nft
        else
            detected_via=os
            mode=legacy
        fi
        ;;

    centos | redhat)
        dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
        maj_ver=$(echo $dist_version | sed -E -e "s/^([0-9]+)\.?[0-9]*$/\1/")
        if [ "$maj_ver" -ge 8 ]; then    
            detected_via=os
            mode=nft
        else
            detected_via=os
            mode=legacy
        fi
        ;;

        # We are running an operating system we don't know, default to nf_tables.
    *)
        detected_via=unknownos
        mode=nft
        ;;

    esac

}

if [ ! -z "$IPTABLES_MODE" ]; then
    mode=${IPTABLES_MODE}
else
    rule_check
    if [ "${mode}" = "unknown" ]; then
        is_containerized
        # If we're containerized, then just fall back to legacy, in hopes `ip_tables` is loaded.
        if [ "${containerized}" = "true" ]; then
            mode=legacy
        else 
            alternatives_check
            if [ "${mode}" = "unknown" ]; then
                os_detect
            fi
        fi
    fi
fi

if [ "${mode}" = "unknown" ]; then
    exit 1
fi

if [ "$(basename $0)" = "iptables-detect.sh" ]; then
    echo mode is $mode detected via $detected_via and containerized is $containerized
    exit 0
fi

xtables-set-mode.sh -m ${mode} >/dev/null

if [ $? = 0 ]; then
    exec "$0" "$@"
else
    exit 1
fi
