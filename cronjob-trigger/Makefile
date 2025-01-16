GO = go
GO_FLAGS =
GOFMT = gofmt
KUBECFG = kubecfg
DOCKER = docker
KUBELESS_IMAGE_REGISTRY ?= docker.io
KUBELESS_IMAGE_REPOSITORY ?= kubeless
KUBELESS_IMAGE_TAG ?= latest
CRONJOB_CONTROLLER_IMAGE = $(KUBELESS_IMAGE_REGISTRY)/$(KUBELESS_IMAGE_REPOSITORY)/kubeless-cronjob-trigger-controller:$(KUBELESS_IMAGE_TAG)
OS = linux
ARCH ?= arm64
BUNDLES = bundles
GO_PACKAGES = ./cmd/... ./pkg/...
GO_FILES := $(shell find $(shell $(GO) list -f '{{.Dir}}' $(GO_PACKAGES)) -name \*.go)

export KUBECFG_JPATH := $(CURDIR)/ksonnet-lib
export PATH := $(PATH):$(CURDIR)/bats/bin

.PHONY: all

default: binary

binary:
	CGO_ENABLED=1 ./script/binary

cronjob-controller-build:
	./script/binary-controller $(OS) $(ARCH) cronjob-controller github.com/kubeless/cronjob-trigger/cmd/cronjob-trigger-controller

cronjob-controller-image: docker/cronjob-controller
	$(DOCKER) build --platform ${OS}/${ARCH} -t $(CRONJOB_CONTROLLER_IMAGE) $<

docker/cronjob-controller: cronjob-controller-build
	cp $(BUNDLES)/kubeless_$(OS)-$(ARCH)/cronjob-controller $@

update:
	./hack/update-codegen.sh

test:
	$(GO) test $(GO_FLAGS) $(GO_PACKAGES)

validation:
	./script/validate-lint
	./script/validate-gofmt
	./script/validate-git-marks

integration-tests:
	./script/integration-tests minikube deployment
	./script/integration-tests minikube basic

fmt:
	$(GOFMT) -s -w $(GO_FILES)

bats:
	git clone --depth=1 https://github.com/sstephenson/bats.git

ksonnet-lib:
	git clone --depth=1 https://github.com/ksonnet/ksonnet-lib.git

.PHONY: bootstrap
bootstrap: bats ksonnet-lib
