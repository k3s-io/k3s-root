ARCH ?= amd64
ALL_ARCH = amd64 arm64 arm ppc64le s390x

export BUILDARCH = $(ARCH)
export VERBOSE ?= 1

TARGETS := $(shell ls scripts)

.dapper:
	@echo Downloading dapper
	@curl -sL https://releases.rancher.com/dapper/latest/dapper-$$(uname -s)-$$(uname -m) > .dapper.tmp
	@@chmod +x .dapper.tmp
	@./.dapper.tmp -v
	@mv .dapper.tmp .dapper

$(TARGETS): .dapper
	./.dapper $@

all-build: $(addprefix sub-build-,$(ALL_ARCH))

sub-build-%:
	$(MAKE) ARCH=$* ci

.DEFAULT_GOAL := ci 

.PHONY: $(TARGETS)
