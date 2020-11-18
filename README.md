# k3s-root
==========

_NOTE: this repository has been recently (2020-11-18) moved out of the github.com/rancher org to github.com/k3s-io
supporting the [acceptance of K3s as a CNCF sandbox project](https://github.com/cncf/toc/pull/447)_.

---

`k3s-root` is based on https://github.com/buildroot/buildroot and provides the userspace binaries for `rancher/k3s`

## Building

`k3s-root` is dapper powered, which means you should be able to simply `make` on your machine to compile. By default, `make` will compile for `amd64`. If you want to compile for other architectures, you can run commands like:
```
make ARCH=arm64
```

or alternatively, if you want to compile all architectures at once, you can run:
```
make all-build
```
