# k3s-root
==========

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

To upgrade to a new buildroot version:

1. Check out a new branch for your work: `git checkout -B bump-buildroot origin/master`
1. Modify the `BUILDROOT_VERSION` in scripts/download
2. Run `make download` to prepare a Docker image for further work 
4. For each target architecture: 
   1. Start a shell in the resulting image: `docker run --rm -it -e BUILDARCH=<ARCH> k3s-root:bump_buildroot /bin/bash`
   2. Run `./scripts/download && ./scripts/patch`
   3. Run `cd /usr/src/buildroot && make olddefconfig`
   4. Outside the container, split changes to the buildroot `.config` into `buildroot/config` and `buildroot/<ARCH>config`
   5. Run `make BUILDARCH=<ARCH>`
   6. Verify if the upgrade worked correctly by comparing the old tarball and the new one. If the same files are there, then you are set.
      If the build failed, or some files are missing, you may need to remove or adapt patches or config for the new buildroot version.
