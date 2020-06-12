# iptables-detect

This is a set of scripts designed to interoperate with the upstream netfilter/iptables 1.8.3 project. The intention of using these scripts is the following:

### Requirements:
1. `xtables-nft-multi` and `xtables-legacy-multi` binaries exist and are in the same folder as the `.sh` scripts
2. Initially, symlinks are set up for `iptables-detect.sh` from `iptables` `ip6tables` `iptables-restore` `ip6tables-restore` `iptables-save` `ip6tables-save`

### Expectations:
When `iptables-detect.sh` is invoked without a symlink in place, it will simply spit out what it detects via what mode. This can be useful for debugging. 

### More Info
The `iptables-detect.sh` script started out as the base `debian-iptables` script from https://github.com/kubernetes/kubernetes/blob/master/build/debian-iptables/iptables-wrapper but was modified to call a designated script called `xtables-set-mode.sh`. This is due to the fact that the original intention of usage of this script was for `k3s-root`, and we should not be updating system level alternatives. In addition, due to the multi-platform nature of K3s, there was no guarantee that `update-alternatives` would even exist on the underlying host system (let alone `/etc/alternatives`) and as such, we only use system-level alternatives to attempt to detect version.