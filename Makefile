ARCH ?= amd64
ALL_ARCH = amd64 arm64 arm ppc64le s390x riscv64

export BUILDARCH = $(ARCH)
export VERBOSE ?= 1

TARGETS := $(shell ls scripts)

.dapper:
	@echo Downloading dapper
	@DAPPER_BINARY="dapper-$$(uname -s)-$$(uname -m)"; \
	case "$$DAPPER_BINARY" in \
		dapper-Linux-x86_64)  DAPPER_SHA256="ff6105ec0a2a973d972810a2dbdb9a6bae65031d286eae082d6779e04e4c2255" ;; \
		dapper-Linux-aarch64) DAPPER_SHA256="cbc133224cca7593482855d8dcdec247288ec83f0fc99fbbe0ad8423260930ff" ;; \
		dapper-Linux-arm)     DAPPER_SHA256="5455fb8663fddc41f32feb426aa85599d7595a87ffed5144e89e1ecc88a3586b" ;; \
		dapper-Darwin-x86_64) DAPPER_SHA256="850e5f867d9d04840b64b159a8a74dcb56f964185c4bd6631941df738cbc98b4" ;; \
		dapper-Darwin-arm64)  DAPPER_SHA256="ca0a5c32341e6474f9140433110153e0eef304ef74d0a830194428b103e7b52e" ;; \
		*) echo "No pinned SHA256 for dapper on platform: $$DAPPER_BINARY" >&2; exit 1 ;; \
	esac; \
	curl -fsSL "https://releases.rancher.com/dapper/latest/$$DAPPER_BINARY" > .dapper.tmp; \
	echo "$$DAPPER_SHA256  .dapper.tmp" | sha256sum -c -
	@chmod +x .dapper.tmp
	@./.dapper.tmp -v
	@mv .dapper.tmp .dapper

$(TARGETS): .dapper
	./.dapper $@

all-build: $(addprefix sub-build-,$(ALL_ARCH))

sub-build-%:
	$(MAKE) ARCH=$* ci

.DEFAULT_GOAL := ci 

.PHONY: $(TARGETS)
