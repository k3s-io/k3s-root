ARCH ?= amd64
ALL_ARCH = amd64 arm64 arm riscv64

export BUILDARCH = $(ARCH)
export VERBOSE ?= 1

TARGETS := $(shell ls scripts)

all-build: $(addprefix sub-build-,$(ALL_ARCH))

sub-build-%:
	$(MAKE) ARCH=$* ci

.DEFAULT_GOAL := ci 

.PHONY: $(TARGETS)

download:
	docker build \
		--build-arg=VERBOSE=$(VERBOSE) \
		--build-arg=BUILDARCH=$(ARCH) \
		-f Dockerfile --target=download --output=type=image,name=k3s-io/k3s-root:dev .

ci:
	docker build \
		--build-arg=VERBOSE=$(VERBOSE) \
		--build-arg=BUILDARCH=$(ARCH) \
		-f Dockerfile --target=result --output=. .
