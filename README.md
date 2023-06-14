# k3s-root
==========

_NOTE: this repository has been  (2020-11-18) moved from the github.com/rancher org to github.com/k3s-io
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

If it is not the first time you build, delete the directories artifacts/ and dist/ to avoid problems when creating the symbolic link in the package step

```
sudo rm -r artifacts/ dist/
```

The default way of building this project is through container using dapper. If you want to tinker and have more control over the build process, it is more practical to use Vagrant with the existing Vagrantfile

## Upgrading to new buildroot version

To upgrade to a new buildroot version, you must follow 4 steps:

1 - Modify the BUILDROOT_VERSION in scripts/download

2 - Check what is the busybox version in the new buildroot package. Then, upgrade the package/busybox.config by cloning the [busybox project](https://github.com/mirror/busybox) and then:
```
git checkout $busybox_version
cp $K3S_ROOT_PATH/package/busybox.config .config
make oldconfig
# Choose the new options
cp .config $K3S_ROOT_PATH/package/busybox.config
```
3 - Follow the same steps with the buildroot/ configurations. The command `make oldconfig` also works in the buildroot project

4 - Verify if the upgrade worked correctly by comparing the old tarball and the new one. If the same files are there, then you are set
