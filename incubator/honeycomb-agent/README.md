# Honeycomb Mixin
> The [Honeycomb Kubernetes agent](https://github.com/honeycombio/honeycomb-kubernetes-agent/tree/master) is a monitoring tool for pods and their containerized applications (e.g. nginx). It continuously observes, parses, and sends their log files to the Honeycomb API, where the data is rendered in a dashboard for real-time observability.

## Overview
The Ksonnet files in this directory generate a Kubernetes JSON config, which can then be used to deploy the [Honeycomb](https://honeycomb.io) monitoring agent to your cluster.

The Honeycomb agent runs as a DaemonSet that collects `stdout` logs from every node. It also leverages pod labels to support application-specific log parsing (e.g. nginx, MySQL).

*Ksonnet logic is intended to be highly composable.* The files are split as follows:

* `honeycomb-agent.libsonnet`: This contains all the core functionality for the Honeycomb agent (e.g. DaemonSet, Secrets, RBAC, volume mounting), which can be invoked and combined in other Ksonnet config files. Generally, you will not need to modify this unless you want to create custom mixins.

* `examples/daemonset.jsonnet`: This file contains:
    * "Meta"-config values (e.g. `secret.key`) that will generate distinct Kubernetes config files if modified. These are detailed  the [configuration section](#configuration).

    * A base Honeycomb DaemonSet that has been combined with a volume-mounting mixin. It attaches three volumes: one volume for the Honeycomb configuration and two volumes to record log output.

* `nginx-app.libsonnet`: This file specifies a sample Nginx app that can be used to test the Honeycomb agent. The pods are tagged with the `app=nginx` label. By default, logs are written to `/var/logs` and `/var/lib/docker/containers` directories.

If you have additional needs, you can add your own functions to the `honeycom-agent.libsonnet` file and mix them in with the DaemonSet from `daemonset.jsonnet`.

## Getting Started

### Prerequisites

* **[BUILD]** *You should have [Jsonnet](http://jsonnet.org/) installed (minimum version 0.9.4).* See [installation instructions](https://github.com/ksonnet/ksonnet-lib#install) if this is not the case.

* **[BUILD]** *You should have cloned or forked the [Ksonnet library](https://github.com/ksonnet/ksonnet-lib) and be on the `honeycomb` branch.* If not:
```
git clone git@github.com:ksonnet/ksonnet-lib.git
git co honeycomb
```

* **[RUN]** *You should have access to an up-and-running Kubernetes cluster.* If you do not have a cluster, follow the [AWS Quickstart Kubernetes Tutorial](http://docs.heptio.com/content/tutorials/aws-cloudformation-k8s.html) to set one up with a single command.

* **[RUN]** *You should have `kubectl` installed.* If not, follow the instructions for [installing via Homebrew (MacOS)](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-with-homebrew-on-macos) or [building the binary (Linux)](https://kubernetes.io/docs/tasks/tools/install-kubectl/#tabset-1).

* **[RUN]** *You should have a Honeycomb account*. [The trial version](https://ui.honeycomb.io/signup) lasts 30 days, which is sufficient for this demo.

* Ideally, you should have some familiarity with Ksonnet syntax, as described in the [official README](http://ksonnet.heptio.com/docs/core-packages/ksonnet-lib.html#write-your-config-files-with-ksonnet).

### Install
Clone or fork this repo:
```
git clone git@github.com:ksonnet/mixins.git
```

### Build

**Honeycomb Agent**

Before building your JSON config, you will need to find your Honeycomb writekey, in order to identify your account to the agent. You can find the writekey on your [account page](https://ui.honeycomb.io/account). Then base64 encode the writekey so that you can use it in a Kubernetes secret:

```
$HONEYCOMB_WRITE_KEY | base64
```

Populate the `conf.secret.key` field in `examples/daemonset.jsonnet` with your Honeycomb account writekey (it is currently set to "foo").

Then run the following command in the current directory (`mixins/incubator/honeycomb`), where `KSONNET_LIB_PATH` points to the home directory of your Ksonnet repo:

```
jsonnet examples/daemonset.jsonnet -J $KSONNET_LIB_PATH examples/daemonset.json
```

**Sample Nginx App**

A Ksonnet config for a generic Nginx app is provided. After building the config, you can easily deploy it to your cluster to make sure that the Honeycomb agent's log collection is working properly.

Run the following:

```
jsonnet examples/nginx_sample.jsonnet -J $KSONNET_LIB_PATH > examples/nginx_sample.json
```

### Run

To start the Honeycomb agent on your cluster, run:

```
kubectl create -f examples/daemonset.json
```

Then deploy the Nginx app:

```
kubectl create -f examples/nginx_sample.json
```

You can check that the agent is successfully running with:

```
kubectl get pods -l k8s-app=honeycomb-agent --namespace=kube-system
```

You should see the following output:

```
NAME                                READY     STATUS    RESTARTS   AGE
honeycomb-agent-v1.1-<PLACEHOLDER>   1/1       Running   0          1h
honeycomb-agent-v1.1-<PLACEHOLDER>   1/1       Running   0          1h
```

You can also check the log output of one of the Honeycomb pods:

```
kubectl logs honeycomb-agent-v1.1-<PLACEHOLDER> --namespace=kube-system
```

The output should show the applied label selectors (e.g. `app=mysql`) and the files that the agent is watching.

## Configuration

### Meta-configs

Below are the descriptions of the values that are set in the `config` variable in `daemonset.jsonnet`:

Name | Default Value | Description | Important to Change?
--- | --- | --- | ---
namespace | "kube-system" | The namespace that all Honeycomb pods are created under | No
rbac.accountname | "honeycomb-serviceaccount" | The name of the ServiceAccount that allows the Honeycomb agent to read pods and node API info. | No
volume.varlogName | "varlog" | The name of the mounted volume that corresponds to log output. | No
volume.podlogsName | "varlibdockercontainers" | The name of the mounted volume that corresponds to log output. | No
configMap.data | YAML config (see code) | The YAML data that configures Honeycomb settings like parser label selectors. See [Honeycomb documentation](https://github.com/honeycombio/honeycomb-kubernetes-agent/blob/master/README.md) for details on available configurations.  | Yes (if you want to change parser behavior)
secret.key | "foo" | The base-64-encoding of your Honeycomb write key. | **Yes.** This must be populated or the Honeycomb agent won't be able to send processed logs to the API for your dashboard.

This `config` is passed in when the base Honeycomb DaemonSet is created.

### Mixins

To define a *new* custom mixin, you can modify the code in `honeycomb-agent.libsonnet`. The file is fairly well documented with comments that should give you a sense of where to change things.

Once your mixin function is defined (whether pre-existing or added by yourself), you can incorporate it into your Honeycomb DaemonSet by using the `daemonSet+::` operator. You can modify the appropriate section of `daemonset.jsonnet` like so:

```
honeycomb.app.daemonSetBuilder.new("honeycomb-agent-v1.1", conf) + {
  // Customizations. Add pod logs to the Honeycomb agent DaemonSet,
  // so that it can tail `stdout` of selected pods.
  daemonSet+:: honeycomb.mixin.daemonSet.addHostMountedPodLogs(conf),

  // custom code below
  daemonSet+:: <MY CUSTOM FUNCTION THAT RETURNS A DAEMONSET MIXIN>
};
```
