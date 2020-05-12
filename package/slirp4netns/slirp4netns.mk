################################################################################
#
# slirp4netns
#
################################################################################

SLIRP4NETNS_VERSION = 6a2bb52fa6d888dc355344c2c45c8a80d1b41c3a
SLIRP4NETNS_SITE = git://github.com/rootless-containers/slirp4netns.git
SLIRP4NETNS_LICENSE = BSD-4-Clause, BSD-2-Clause

# As we're using the git tree, there's no ./configure,
# so we need to autoreconf.
SLIRP4NETNS_AUTORECONF = YES

$(eval $(autotools-package))
