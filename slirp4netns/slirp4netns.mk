################################################################################
#
# slirp4netns
#
################################################################################

SLIRP4NETNS_VERSION = v1.0.1
SLIRP4NETNS_SITE = git://github.com/rootless-containers/slirp4netns.git
SLIRP4NETNS_LICENSE = GPL-2.0-or-later

# As we're using the git tree, there's no ./configure,
# so we need to autoreconf.
SLIRP4NETNS_AUTORECONF = YES

$(eval $(autotools-package))
