# Kubeless on Raspberry Pi in 2024

This repository is a fork of [`vmware-archive/kubeless`](https://github.com/vmware-archive).
We run Kubeless on a Raspberry Pi 3/4 with Raspberry Pi OS (Debian Bookworm) in 2024.
This is based on release `v1.0.8` of Kubeless.

## Building

We need to build both the Kubeless container images and the `kubeless` CLI tool.

### CLI

The `kubeless` CLI tool is only released as an `x86` binary, we build it for `arm64` to run on Raspberry Pi.
These steps are performed on an M1 MacBook Pro (with `arm64`):

```sh
docker run --platform linux/arm64 -it --rm \
    -v $(pwd):/kubeless \
    golang:1.23-bookworm \
    /bin/bash

# now inside the container
cd /kubeless
go build -o kubeless ./cmd/kubeless
```

You now have the binary `kubeless` build for Linux `arm64`.

### Containers

```sh
make bootstrap
```

## Deploying

We assume a Raspberry Pi 3/4 with Raspberry Pi OS.

1. Enable the memory `cgroup` by adding the following line at the end of `/boot/firmware/cmdline.txt`:

    ```config
    cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1
    ```

1. Disable swapping on the Raspberry Pi:

    ```sh
    sudo dphys-swapfile swapoff
    sudo dphys-swapfile uninstall
    sudo update-rc.d dphys-swapfile remove
    sudo apt purge dphys-swapfile -y
    sudo sysctl -w vm.swappiness=0
    ```

1. Install Kubernetes (we use `k3s`) with version `<1.22`:

    ```sh
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.21.14+k3s1" sh -
    ```

    `k3s` can be uninstalled with `/usr/local/bin/k3s-uninstall.sh`.

1. Check that `k3s` works properly (may need to wait ~30 seconds before this works):

    ```sh
    $ sudo k3s kubectl get node
    NAME   STATUS   ROLES                  AGE   VERSION
    pi3    Ready    control-plane,master   20s   v1.31.3+k3s1
    ```

1. Install Kubeless on your cluster:

    ```sh
    RELEASE=v1.0.8
    sudo k3s kubectl create ns kubeless
    sudo k3s kubectl create -f https://github.com/kubeless/kubeless/releases/download/$RELEASE/kubeless-non-rbac-$RELEASE.yaml --validate=false
    ```

    You can check that everything worked using the `kubectl get` commands:

    ```sh
    sudo k3s kubectl get pods -n kubeless
    sudo k3s kubectl get deployment -n kubeless
    sudo k3s kubectl get customresourcedefinition
    ```

1. Copy the `kubeless` CLI (built earlier) to your device.
    Test it:

    ```sh
    ./kubeless get-server-config
    ```

1. Create a function, e.g., using Python3:

    ```sh

    cat <<EOF > kfunc.py
    def hello(event, context):
        print (event)
        return event['data']
    EOF

    kubeless function deploy hello --runtime python3.8 \
                                --from-file test.py \
                                --handler test.hello
    ```

---

# <img src="https://cloud.githubusercontent.com/assets/4056725/25480209/1d5bf83c-2b48-11e7-8db8-bcd650f31297.png" alt="Kubeless logo" width="400">

[![CircleCI](https://circleci.com/gh/kubeless/kubeless.svg?style=svg)](https://circleci.com/gh/kubeless/kubeless)
[![Slack](https://img.shields.io/badge/slack-join%20chat%20%E2%86%92-e01563.svg)](http://slack.k8s.io)
[![Not Maintained](https://img.shields.io/badge/Maintenance%20Level-Not%20Maintained-yellow.svg)](https://gist.github.com/cheerfulstoic/d107229326a01ff0f333a1d3476e068d)

## WARNING: Kubeless is no longer actively maintained by VMware.

VMware has made the difficult decision to stop driving this project and therefore we will no longer actively respond to issues or pull requests. If you would like to take over maintaining this project independently from VMware, please let us know so we can add a link to your forked project here.

Thank You.

## Overview

`kubeless` is a Kubernetes-native serverless framework that lets you deploy small bits of code without having to worry about the underlying infrastructure plumbing. It leverages Kubernetes resources to provide auto-scaling, API routing, monitoring, troubleshooting and more.

Kubeless stands out as we use a [Custom Resource Definition](https://kubernetes.io/docs/tasks/access-kubernetes-api/extend-api-custom-resource-definitions/) to be able to create functions as custom kubernetes resources. We then run an in-cluster controller that watches these custom resources and launches _runtimes_ on-demand. The controller dynamically injects the functions code into the runtimes and make them available over HTTP or via a PubSub mechanism.

Kubeless is purely open-source and non-affiliated to any commercial organization. Chime in at anytime, we would love the help and feedback !

## Tools

* A [UI](https://github.com/kubeless/kubeless-ui) is available. It can run locally or in-cluster.
* A [serverless framework plugin](https://github.com/serverless/serverless-kubeless) is available.

## Quick start

Check out the instructions for quickly set up Kubeless [here](http://kubeless.io/docs/quick-start).

## Building

Consult the [developer's guide](docs/dev-guide.md) for a complete set of instruction
to build kubeless.

## Compatibility Matrix with Kubernetes

Kubeless fully supports Kubernetes versions greater than 1.9 (tested until 1.15). For other versions some of the features in Kubeless may not be available. Our CI run tests against two different platforms: GKE (1.12) and Minikube (1.15). Other platforms are supported but fully compatibiliy cannot be assured.

## _Roadmap_

We would love to get your help, feel free to lend a hand. We are currently looking to implement the following high level features:

* Add other runtimes, currently Golang, Python, NodeJS, Ruby, PHP, .NET and Ballerina are supported. We are also providing a way to use custom runtime. Please check [this doc](./docs/runtimes.md) for more details.
* Investigate other messaging bus (e.g SQS, rabbitMQ)
* Optimize for functions startup time
* Add distributed tracing (maybe using istio)

## Community

**Issues**: If you find any issues, please [file it](https://github.com/kubeless/kubeless/issues).

**Slack**: We're fairly active on [slack](http://slack.k8s.io) and you can find us in the #kubeless channel.
