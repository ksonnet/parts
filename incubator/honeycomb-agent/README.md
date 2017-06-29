# Honeycomb Mixin
> The [Honeycomb Kubernetes agent](https://github.com/honeycombio/honeycomb-kubernetes-agent/tree/master) is a monitoring tool for pods and their containerized applications (e.g. nginx). It continuously observes, parses, and sends their log files to the Honeycomb API, where the data is rendered in a dashboard for real-time observability.

## Overview
The Ksonnet files in this directory generate a Kubernetes JSON config, which can then be used to deploy the [Honeycomb](https://honeycomb.io) monitoring agent to your cluster.

The Honeycomb agent runs as a DaemonSet that collects `stdout` logs from every node. It also leverages pod labels to support application-specific log parsing (e.g. nginx, MySQL). To learn how to configure this and other capabilities, see the [ README](https://github.com/honeycombio/honeycomb-kubernetes-agent/blob/master/README.md) for the agent.

*The Ksonnet files themselves are intended to be highly composable.* They are broken down as follows:
* `honeycomb-agent-ds-base.libsonnet`: This file is the bare-bones. It specifies (1) a DaemonSet that runs the Honeycomb agent image and (2) the necessary RBAC resources for establishing pod API permissions, but nothing else.

* `honeycomb-agent-ds-custom.libsonnet`: This file defines various [pluggable mixins](http://ksonnet.heptio.com/#pluggable), which allow you to selectively add features onto the DaemonSet from the `base` file.  

* `honeycomb-agent-ds-app.jsonnet`: This file demonstrates an example of how the `base` DaemonSet can be combined with `custom` plugins. It mounts three volumes: one volume for the Honeycomb configuration and two volumes to record log output.

* `nginx-app.libsonnet`: This file specifies a sample Nginx app that can be used to test the Honeycomb agent. The pods are tagged with the `app=nginx` label. By default, logs are written to `/var/logs` and `/var/lib/docker/containers` directories.

If you have additional needs, you can add your own functions to the `custom` file and mix them in with the `base` Honeycomb DaemonSet. Also, see the [configuration section](#configuration) for more details.

## Getting Started
### Prerequisites
* [BUILD] *You should have [Jsonnet](http://jsonnet.org/) installed (minimum version 0.9.4).* See [installation instructions](https://github.com/ksonnet/ksonnet-lib#install) if this is not the case.

* [BUILD] *You should have created a Secret and a ConfigMap for your cluster, which can be used to mount information such as your unique Honeycomb writekey and log parser settings.* See the [`honeycomb-kubernetes-agent` quickstart](https://github.com/honeycombio/honeycomb-kubernetes-agent/tree/devel#quickstart) for instructions.

* [RUN] *You should have access to an up-and-running Kubernetes cluster.* If you do not have a cluster, follow the [AWS Quickstart Kubernetes Tutorial](http://docs.heptio.com/content/tutorials/aws-cloudformation-k8s.html) to set one up with a single command.

* [RUN] *You should have `kubectl` installed.* If not, follow the instructions for [installing via Homebrew (MacOS)](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-with-homebrew-on-macos) or [building the binary (Linux)](https://kubernetes.io/docs/tasks/tools/install-kubectl/#tabset-1).

* Ideally, you should have some familiarity with Ksonnet syntax, as described in the [official README](http://ksonnet.heptio.com/docs/core-packages/ksonnet-lib.html#write-your-config-files-with-ksonnet).

### Install
Clone or fork this Ksonnet repo:
```
git clone git@github.com:ksonnet/ksonnet-lib.git
```

### Build

Run the following command in the current directory (`ksonnet-lib/mixins/honeycomb`), where `KSONNET_LIB_PATH` is the home directory of your Ksonnet repo:

```
jsonnet honeycomb-agent-ds-app.jsonnet -J <KSONNET_LIB_PATH> > honeycomb-agent-ds-app.json
```

### Run

To start the Honeycomb agent on your cluster, run:
```
kubectl create -f honeycomb-agent-ds-app.json
```


## Configuration
break down how existing ksonnet file works

extensions/ideas for other ksonnet files?
