################################################################################
#
# slirp4netns
#
################################################################################

SLIRP4NETNS_VERSION = v0.4.3
SLIRP4NETNS_SITE = git://github.com/rootless-containers/slirp4netns.git
SLIRP4NETNS_LICENSE = BSD-4-Clause, BSD-2-Clause

# As we're using the git tree, there's no ./configure,
# so we need to autoreconf.
SLIRP4NETNS_AUTORECONF = YES

$(eval $(autotools-package))
