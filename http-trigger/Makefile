GO = go
GO_FLAGS =
GOFMT = gofmt
KUBECFG = kubecfg
DOCKER = docker
KUBELESS_IMAGE_REGISTRY ?= docker.io
KUBELESS_IMAGE_REPOSITORY ?= kubeless
KUBELESS_IMAGE_TAG ?= latest
HTTP_CONTROLLER_IMAGE = $(KUBELESS_IMAGE_REGISTRY)/$(KUBELESS_IMAGE_REPOSITORY)/kubeless-http-trigger-controller:$(KUBELESS_IMAGE_TAG)
OS = linux
ARCH ?= arm64
BUNDLES = bundles
GO_PACKAGES = ./cmd/... ./pkg/...
GO_FILES := $(shell find $(shell $(GO) list -f '{{.Dir}}' $(GO_PACKAGES)) -name \*.go)

export KUBECFG_JPATH := $(CURDIR)/ksonnet-lib
export PATH := $(PATH):$(CURDIR)/bats/bin

.PHONY: all

KUBELESS_ENVS := \
	-e OS_PLATFORM_ARG \
	-e OS_ARCH_ARG \

default: binary

binary:
	CGO_ENABLED=1 ./script/binary

http-controller-build:
	./script/binary-controller $(OS) $(ARCH) http-controller ./cmd/http-trigger-controller

http-controller-image: docker/http-controller
	$(DOCKER) build --platform ${OS}/${ARCH} -t $(HTTP_CONTROLLER_IMAGE) $<

docker/http-controller: http-controller-build
	cp $(BUNDLES)/kubeless_$(OS)-$(ARCH)/http-controller $@

update:
	./hack/update-codegen.sh

test:
	$(GO) test $(GO_FLAGS) $(GO_PACKAGES)

validation:
	./script/validate-vet
	./script/validate-lint
	./script/validate-gofmt
	./script/validate-git-marks

fmt:
	$(GOFMT) -s -w $(GO_FILES)

bats:
	git clone --depth=1 https://github.com/sstephenson/bats.git

ksonnet-lib:
	git clone --depth=1 https://github.com/ksonnet/ksonnet-lib.git

.PHONY: bootstrap
bootstrap: bats ksonnet-lib

.PHONY: build-manifests
build-manifests:
	./script/build-manifests.sh
