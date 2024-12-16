GO = go
GO_FLAGS =
GOFMT = gofmt
KUBECFG = kubecfg
DOCKER = docker
KUBELESS_IMAGE_REGISTRY ?= docker.io
KUBELESS_IMAGE_REPOSITORY ?= kubeless
KUBELESS_IMAGE_TAG ?= latest
CONTROLLER_IMAGE = $(KUBELESS_IMAGE_REGISTRY)/$(KUBELESS_IMAGE_REPOSITORY)/kubeless-function-controller:$(KUBELESS_IMAGE_TAG)
FUNCTION_IMAGE_BUILDER = $(KUBELESS_IMAGE_REGISTRY)/$(KUBELESS_IMAGE_REPOSITORY)/kubeless-function-image-builder:$(KUBELESS_IMAGE_TAG)
OS = linux
ARCH = arm64
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
	CGO_ENABLED=0 ./script/binary

binary-cross:
	./script/binary-cli


%.yaml: %.jsonnet
	$(KUBECFG) show -U https://raw.githubusercontent.com/kubeless/runtimes/master -o yaml $< > $@.tmp
	mv $@.tmp $@

all-yaml: kubeless.yaml kubeless-non-rbac.yaml kubeless-openshift.yaml

kubeless.yaml: kubeless.jsonnet kubeless-non-rbac.jsonnet

kubeless-non-rbac.yaml: kubeless-non-rbac.jsonnet

kubeless-openshift.yaml: kubeless-openshift.jsonnet

docker/function-controller: controller-build
	cp $(BUNDLES)/kubeless_$(OS)-$(ARCH)/kubeless-function-controller $@

controller-build:
	./script/binary-controller -os=$(OS) -arch=$(ARCH)

function-controller: docker/function-controller
	$(DOCKER) build -t $(CONTROLLER_IMAGE) $<

docker/function-image-builder: function-image-builder-build
	cp $(BUNDLES)/kubeless_$(OS)-$(ARCH)/imbuilder $@

function-image-builder-build:
	./script/binary-controller -os=$(OS) -arch=$(ARCH) imbuilder github.com/kubeless/kubeless/pkg/function-image-builder

function-image-builder: docker/function-image-builder
	$(DOCKER) build -t $(FUNCTION_IMAGE_BUILDER) $<

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
	git clone --branch=v0.4.0 --depth=1 https://github.com/sstephenson/bats.git

ksonnet-lib:
	git clone --depth=1 https://github.com/ksonnet/ksonnet-lib.git

.PHONY: bootstrap
bootstrap: bats ksonnet-lib

